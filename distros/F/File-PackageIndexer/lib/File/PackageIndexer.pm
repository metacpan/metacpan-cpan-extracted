package File::PackageIndexer;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.02';

use PPI;
use Carp;
require File::PackageIndexer::PPI::Util;
require File::PackageIndexer::PPI::ClassXSAccessor;
require File::PackageIndexer::PPI::Inheritance;

use Class::XSAccessor
  accessors => {
    default_package => 'default_package',
    clean => 'clean',
  };

sub new {
  my $class = shift;
  my $self = bless {
    clean => 1,
    @_
  } => $class;
  return $self;
}

sub parse {
  my $self = shift;
  my $def_pkg = $self->default_package;
  $def_pkg = 'main', $self->default_package('main')
    if not defined $def_pkg;

  my $doc = shift;
  if (not ref($doc) or not $doc->isa("PPI::Node")) {
    $doc = PPI::Document->new(\$doc);
  }
  if (not ref($doc)) {
    return();
  }
  
  my $curpkg;
  my $pkgs = {};

  # TODO: More accessor generators et al
  # TODO: More inheritance
  # TODO: package statement scopes

  my $in_scheduled_block = 0;
  my $finder;
  use Data::Dumper;
  $finder = sub {
    return(0) unless $_[1]->isa("PPI::Statement");
    my $statement = $_[1];

    my $class = $statement->class;
    # BEGIN/CHECK/INIT/UNITCHECK/END:
    # Recurse and set the block state, then break outer
    # recursion so we don't process twice
    if ( $class eq 'PPI::Statement::Scheduled' ) {
      my $temp_copy = $in_scheduled_block;
      $in_scheduled_block = $statement->type;
      $statement->find($finder);
      $in_scheduled_block = $temp_copy;
      return undef;
    }
    # new sub declaration
    elsif ( $class eq 'PPI::Statement::Sub' ) {
      my $subname = $statement->name;
      if (not defined $curpkg) {
        $curpkg = $self->lazy_create_pkg($def_pkg, $pkgs);
      }
      $curpkg->{subs}->{$subname} = 1;
    }
    # new package statement
    elsif ( $class eq 'PPI::Statement::Package' ) {
      my $namespace = $statement->namespace;
      $curpkg = $self->lazy_create_pkg($namespace, $pkgs);
    }
    # use()
    elsif ( $class eq 'PPI::Statement::Include' ) {
      $self->_handle_includes($statement, $curpkg, $pkgs);
    }
    elsif ( $statement->find_any(sub {$_[1]->class eq "PPI::Token::Symbol" and $_[1]->content eq '@ISA'}) ) {
      File::PackageIndexer::PPI::Inheritance::handle_isa($self, $statement, $curpkg, $pkgs, $in_scheduled_block);
    }
  };

  # run it
  $doc->find($finder);

  foreach my $token ( $doc->tokens ) {
    # find Class->method and __PACKAGE__->method
    my ($callee, $methodname) = File::PackageIndexer::PPI::Util::is_class_method_call($token);

    if ($callee and $methodname =~ /^(?:mk_(?:[rw]o_)?accessors)$/) {
      # resolve __PACKAGE__ to current package
      if ($callee eq '__PACKAGE__') {
        $callee = defined($curpkg) ? $curpkg->{name} : $def_pkg;
      }

      my $args = $token->snext_sibling->snext_sibling->snext_sibling; # class->op->method->structure
      if (defined $args and $args->isa("PPI::Structure::List")) {
        my $list = File::PackageIndexer::PPI::Util::list_structure_to_array($args);
        if (@$list) {
          my $pkg = $self->lazy_create_pkg($callee, $pkgs);
          $pkg->{subs}{$_} = 1 for @$list;
        }
      }

    }
  }


  # prepend unshift()d inheritance to the
  # compile-time ISA, then append the push()d
  # inheritance
  foreach my $pkgname (keys %$pkgs) {
    my $pkg = $pkgs->{$pkgname};

    my $isa = [ @{$pkg->{begin_isa}} ];
    if ($pkg->{isa_cleared_at_runtime}) {
      $isa = [];
    }

    unshift @$isa, @{ $pkg->{isa_unshift} };
    push    @$isa, @{ $pkg->{isa_push} };

    if ($self->clean) {
      delete $pkg->{begin_isa};
      delete $pkg->{isa_unshift};
      delete $pkg->{isa_push};
      delete $pkg->{isa_cleared_at_runtime};
      delete $pkg->{isa_cleared_at_compiletime};
    }

    $pkg->{isa} = $isa;
  }

  return $pkgs;
}

# generate empty, new package struct
sub lazy_create_pkg {
  my $self = shift;
  my $p_name = shift;
  my $pkgs = shift;
  return $pkgs->{$p_name} if exists $pkgs->{$p_name};
  $pkgs->{$p_name} = {
    name => $p_name,
    subs => {},
    isa_unshift => [], # usa entries unshifted at run-time
    isa_push => [], # isa entries pushed at run-time
    begin_isa  => [], # temporary storage for compile-time inheritance, will be deleted before returning from parse()
  };
  return $pkgs->{$p_name};
}


# try to deduce info from module loads
sub _handle_includes {
  my $self = shift;
  my $statement = shift;
  my $curpkg = shift;
  my $pkgs = shift;

  return
    if $statement->type ne 'use'
    or not defined $statement->module;

  my $module = $statement->module;

  if ($module =~ /^Class::XSAccessor(?:::Array)?$/) {
    File::PackageIndexer::PPI::ClassXSAccessor::handle_class_xsaccessor($self, $statement, $curpkg, $pkgs);
  }
  elsif ($module =~ /^(?:base|parent)$/) {
    File::PackageIndexer::PPI::Inheritance::handle_base($self, $statement, $curpkg, $pkgs);
  }

  # TODO: handle other generating modules loaded via use
  
  # TODO: Elsewhere, we need to handle Class->import()!
}


sub merge_results {
  my @results = @_;
  shift @results while @results and !ref($results[0]) || ref($results[0]) eq 'File::PackageIndexer';
  return merge_results_inplace({}, @results);
}

sub merge_results_inplace {
  my @results = @_;
  shift @results while @results and !ref($results[0]) || ref($results[0]) eq 'File::PackageIndexer';

  return @results if @results == 1;

  # check that the user used things right
  foreach my $r (@results) {
    foreach my $pkg (values %$r) {
      if (not exists $pkg->{begin_isa}) {
        croak("Can't merge results that have been cleaned. Set the 'clean' option of the parser to a false value to disable cleaning of the result structures. Also RTFM.");
      }
    }
  }

  my $res = shift(@results);
  foreach my $in (@results) {

    foreach my $pkgname (keys %$in) {
      my $inpkg = $in->{$pkgname};
      if (not exists $res->{$pkgname}) {
        $res->{$pkgname} = $inpkg;
      }
      # merge!
      else {
        my $pkg = $res->{$pkgname};

        # handle compile time isa
        if ($inpkg->{isa_cleared_at_compiletime}) {
          $pkg->{begin_isa} = [@{$inpkg->{begin_isa}}];
          $pkg->{isa_cleared_at_compiletime} = 1;
        }
        else {
          push @{$pkg->{begin_isa}}, @{$inpkg->{begin_isa}};
        }

        # handle run-time isa
        if ($inpkg->{isa_cleared_at_runtime}) {
          $pkg->{isa_unshift} = [@{$inpkg->{isa_unshift}}];
          $pkg->{isa_push}    = [@{$inpkg->{isa_push}}];
          $pkg->{isa_cleared_at_runtime} ||= $inpkg->{isa_cleared_at_runtime};
        }
        else {
          unshift @{$pkg->{isa_unshift}}, @{$inpkg->{isa_unshift}};
          push    @{$pkg->{isa_push}},    @{$inpkg->{isa_push}};
        }

        # finalize isa
        my $isa = [];
        @$isa = @{$pkg->{begin_isa}};
        if ($pkg->{isa_cleared_at_runtime}) {
          $isa = [];
        }

        unshift @$isa, @{ $pkg->{isa_unshift} };
        push    @$isa, @{ $pkg->{isa_push} };

        $pkg->{isa} = $isa;

        # merge subs
        my $subs = $pkg->{subs};
        foreach my $insub (keys %{$inpkg->{subs}}) {
          $subs->{$insub} = 1;
        }

      } # end merge

    } #  end foreach packages
  } # end foreach @results
  
  return $res;
}


sub clean_results {
  my @results = @_;
  shift @results while @results and !ref($results[0]) || ref($results[0]) eq 'File::PackageIndexer';

  return({}) if not @results;
  my $in = $results[0];

  my $res = {};
  foreach my $pkgname (keys %{$in}) {
    my $inpkg = $in->{$pkgname};
    my $pkg = $res->{$pkgname} = {};
    $pkg->{subs} = {%{$inpkg->{subs}}};
    $pkg->{isa} = [@{$inpkg->{isa}}];
    $pkg->{name} = $inpkg->{name};
  }
  
  return $res;
}

1;

__END__

=head1 NAME

File::PackageIndexer - Indexing of packages and subs

=head1 SYNOPSIS

  use File::PackageIndexer;
  my $indexer = File::PackageIndexer->new();
  $indexer->clean(1);
  my $pkgs = $indexer->parse( $ppi_document_or_code_string );
  
  use Data::Dumper;
  print Dumper $pkgs;
  # prints something like:
  # {
  #   Some::Package => {
  #     name => 'Some::Package',
  #     subs => {
  #       new => 1,
  #       foo => 1,
  #     },
  #     isa => [ 'SuperClass1', 'SuperClass2' ],
  #   },
  #   ... other pkgs ...
  # }

=head1 DESCRIPTION

Parses a piece of Perl code using PPI and tries to find all subs
and their packages as well as the inheritance of the packages.

Currently, the following constructs are recognized:

=over 2

=item C<package> statements

=item plain subroutine declarations

=item C<Class::Accessor>-like accessor generation

=item C<Class::XSAccessor> and C<Class::XSAccessor::Array>

=item C<use base ...> inheritance declaration

=item C<use parent ...> inheritance declaration

=item C<our @ISA = ...> and C<@ISA = ...> inheritance declaration

=item C<push @ISA, ...> and C<unshift @ISA, ...> inheritance modification

=back

The inheritance detection (hopefully) correctly recognizes the effect of special
blocks such as C<BEGIN {...}>. C<END> blocks are ignored.

=head1 METHODS

=head2 new

Creates a new indexer object. Optional parameters:

=over 2

=item default_package

The default package to assume a subroutine is in if no
package statement was found beforehand. Defaults to C<main>.

=item clean 

Whether or not the internal result hash keys should be cleaned up or not.
By default, these are cleaned. Set this to false if you plan to merge
multiple result sets!

=back

=head2 default_package

Get/set default package.

=head2 parse

Parses a given  piece of code. Alternatively, you may
pass in a C<PPI::Node> or C<PPI::Document> object.

Returns a simple hash-ref based structure containing the
packages and subs found in the code. General structure:

  {
    'Package::Name' => {
      subs => {
        subname1 => 1,
        subname2 => 1,
        ... more subs ...
      },
    },
    ... more packages ...
  }

=head2 merge_results

Can be called either as an instance or class method as well as a function.
Expects an arbitrary number of parse results as argument and merges them
into one as well as possible. If there are collisions (specifically wrt.
inheritance), they are resolved in favour of the later results. That is,
if result set one and two conflict, two takes precedence.

This function/method can only handle results that have not been cleaned up.
Set the C<clean> option to false to disable cleaning of internal information.
Use the C<clean_results> function/method to clean up the merged result set.

Returns the merged result set.

I<Note:> Currently, this may do shallow copies of some sub-structures.

=head2 merge_results_inplace

Same as C<merge_results>, but assigns the result to the first result
set passed in.

=head2 clean_results

Can be called either as an instance or class method as well as a function.
Expects a result set as argument. Returns the cleaned result set.

=head1 SEE ALSO

Implemented using L<PPI>.

=head1 TODO

Maybe other constructs that affect inheritance?

Exporting! (yuck)

Other accessor generators.

C<use constant ...> Seems simple but it is not.

Moose. This is going to be tough, but mandatory.

C<Class->import(...)> is currently not handled akin to C<use Class ...>.

General dependency resolution.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
