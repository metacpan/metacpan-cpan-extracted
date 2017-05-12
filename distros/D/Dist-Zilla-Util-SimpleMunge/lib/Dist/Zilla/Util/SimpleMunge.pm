use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Util::SimpleMunge;

our $VERSION = '1.000002';

# ABSTRACT: Make munging File::FromCode and File::InMemory easier.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Sub::Exporter -setup => { exports =>
    [qw[ munge_file munge_files to_InMemory to_FromCode munge_InMemory munge_FromCode inplace_replace auto_munge_file ]], };









































































































my $ex_auto_munge_file_params_excess = {
  tags => [qw( parameters excess auto_munge_file )],
  ## no critic (RequireInterpolationOfMetachars)
  message => q[auto_munge_file only accepts 2 parameters, $FILE and $CALLBACK],
  id      => 'auto_munge_file_params_excess',
};

my $ex_auto_munge_file_param_file_bad = {
  tags => [qw( parameters file bad mismatch invalid )],
  id   => 'auto_munge_file_param_file_bad',
  ## no critic (ValuesAndExpressions::RestrictLongStrings)
  message => 'auto_munge_file must be passed a Dist::Zilla File or a compatible object for parameter 0',
};

sub auto_munge_file {
  my (@all) = @_;
  my ( $file, $callback, @rest ) = @all;
  if (@rest) {
    __PACKAGE__->_error(
      %{$ex_auto_munge_file_params_excess},
      payload => {
        parameters => \@all,
        errors     => \@rest,
        understood => {
          qw( $file )     => $file,
          qw( $callback ) => $callback,
        },
      },
    );
  }
  if ( not $file or not $file->can('content') ) {
    __PACKAGE__->_error(
      %{$ex_auto_munge_file_param_file_bad},
      payload => {
        parameter_no => 0,
        expects      => [qw[ defined ->can(content) ]],
        got          => $file,
      },
    );
  }
  if ( not defined $callback or not 'CODE' eq ref $callback ) {
    __PACKAGE__->_error(
      message => 'auto_munge_file must be passed a subroutine as parameter 1',
      payload => {
        parameter_no => '1',
        expects      => [qw[ defined ref Code ]],
        got          => $callback,
      },
      id   => 'auto_munge_file_callback_bad',
      tags => [qw( parameters config via bad mismatch invalid )],
    );
  }
  if ( $file->can('code') ) {
    return munge_FromCode( $file, $callback );
  }
  return munge_InMemory( $file, $callback );

}










sub to_InMemory {
  my ($file)   = @_;
  my $encoding = $file->encoding;
  my %args     = (
    name     => $file->name,
    encoding => $encoding,
    added_by => $file->added_by,
    mode     => $file->mode,
  );
  if ( 'bytes' eq $encoding ) {
    $args{encoded_content} = $file->encoded_content;
  }
  else {
    $args{content} = $file->content;
  }
  require Dist::Zilla::File::InMemory;
  return Dist::Zilla::File::InMemory->new(%args);
}









sub to_FromCode {
  my ($file)   = @_;
  my $encoding = $file->encoding;
  my %args     = (
    name     => $file->name,
    added_by => $file->added_by,
    mode     => $file->mode,
  );
  if ( 'bytes' eq $encoding ) {
    my $ec = $file->encoded_content;
    $args{code} = sub { return $ec };
    $args{code_return_type} = 'bytes';
  }
  else {
    my $c = $file->content;
    $args{code} = sub { return $c };
    $args{code_return_type} = 'text';
  }
  require Dist::Zilla::File::FromCode;
  return Dist::Zilla::File::FromCode->new(%args);
}















sub munge_InMemory {
  my ( $file, $coderef ) = @_;
  if ( 'bytes' eq $file->encoding ) {
    return $file->encoded_content( $coderef->( $file, $file->content, 'bytes' ) );
  }
  $file->content( $coderef->( $file, $file->content, 'text' ) );
  return 1;
}




























sub munge_FromCode {
  my ( $file, $coderef ) = @_;
  my $oldcoderef  = $file->code;
  my $return_type = $file->code_return_type;
  $file->code(
    sub {
      $coderef->( $file, $oldcoderef->(), $return_type );
    },
  );
  return 1;
}

use Scalar::Util qw(blessed);








































# This is a little bit nasty, but can you suggest a better way?
# TODO
sub inplace_replace {
  my ( $orig, $replacement ) = @_;
  my $newclass = blessed $replacement;
  for my $oldkey ( keys %{$orig} ) {
    delete $orig->{$oldkey};
  }
  for my $newkey ( keys %{$replacement} ) {
    $orig->{$newkey} = $replacement->{$newkey};
  }
  bless $orig, $newclass;
  return 1;
}









sub inplace_to_FromCode {
  my ($file) = @_;
  return inplace_replace( $file, to_FromCode($file) );
}









sub inplace_to_InMemory {
  my ($file) = @_;
  return inplace_replace( $file, to_InMemory($file) );
}





























































sub _fromcode_munge {
  my ( $file, $config ) = @_;
  if ( defined $config->{lazy} and 0 == $config->{lazy} ) {
    inplace_to_InMemory($file);
    munge_InMemory( $file, $config->{via} );
    return 1;
  }
  munge_FromCode( $file, $config->{via} );
  return 1;
}

sub _scalar_munge {
  my ( $file, $config ) = @_;
  if ( defined $config->{lazy} and 1 == $config->{lazy} ) {
    inplace_to_FromCode($file);
    munge_FromCode( $file, $config->{via} );
    return 1;
  }
  munge_InMemory( $file, $config->{via} );
  return 1;
}

my $ex_munge_file_params_excess = {
  tags => [qw( parameters excess munge_file )],
  id   => 'munge_file_params_excess',
  ## no critic (RequireInterpolationOfMetachars)
  message => q[munge_file only accepts 2 parameters, $FILE and \%CONFIG],
};
my $ex_munge_file_param_file_bad = {
  id   => 'munge_file_param_file_bad',
  tags => [qw( parameters file bad mismatch invalid )],
  ## no critic (ValuesAndExpressions::RestrictLongStrings)
  message => 'munge_file must be passed a Dist::Zilla File or a compatible object for parameter 0',
};

sub munge_file {
  my (@all) = @_;
  my ( $file, $config, @rest ) = @all;

  if (@rest) {
    __PACKAGE__->_error(
      %{$ex_munge_file_params_excess},
      payload => {
        parameters => \@all,
        errors     => \@rest,
        understood => {
          qw( $file )   => $file,
          qw( $config ) => $config,
        },
      },
    );
  }

  if ( not $file or not $file->can('content') ) {
    __PACKAGE__->_error(
      %{$ex_munge_file_param_file_bad},
      payload => {
        parameter_no => 0,
        expects      => [qw[ defined ->can(content) ]],
        got          => $file,
      },
    );
  }

  if ( not ref $config or not 'HASH' eq ref $config ) {
    __PACKAGE__->_error(
      message => 'munge_file must be passed a HashReference for parameter 1',
      payload => {
        parameter_no => 1,
        expects      => [qw[ defined ref Hash ]],
        got          => $file,
      },
      id   => 'munge_file_param_config_bad',
      tags => [qw( parameters config bad mismatch invalid )],
    );
  }

  if ( not exists $config->{via} or not defined $config->{via} or not 'CODE' eq ref $config->{via} ) {
    __PACKAGE__->_error(
      message => 'munge_file must be passed a subroutine in the configuration hash as \'via\'',
      payload => {
        parameter_name => 'via',
        expects        => [qw[ exists defined ref Code ]],
        got            => $config->{via},
      },
      id   => 'munge_file_config_via_bad',
      tags => [qw( parameters config via bad mismatch invalid )],
    );
  }

  if (
    exists $config->{lazy}
    and not( ( not defined $config->{lazy} )
      or ( 0 == $config->{lazy} )
      or ( 1 == $config->{lazy} ) )
    )
  {
    __PACKAGE__->_error(
      message => 'munge_file configuration value \'lazy\' must be un-set, undef, 0 or 1',
      payload => {
        parameter_name => 'lazy',
        expects_one    => [qw[ unset undef 0 1 ]],
        got            => $config->{lazy},
      },
      id   => 'munge_file_config_lazy_bad',
      tags => [qw( parameters config lazy bad mismatch invalid )],
    );
  }

  # This codeblock exists for permitting one or more forms of "native" munging.
  # Presently undocumented as the underlying support is still non-existent.
  #
  # There is only presently one supported option
  #    { native => "filemungeapi" }
  # which will call the ->munge method on the file instance
  # using the form currently defined by this pull request:
  #
  #   https://github.com/rjbs/dist-zilla/pull/24
  #
  # This allows for per-file custom class methods for defining exactly how munge is performed
  # but presently lacks passing arbitrary munge control flags ( ie: forced lazy etc )
  #
  # If it doesn't look like the file in question conforms to the requested munge api,
  # then it falls back to traditional dzil.
  #
  # An object with a ->code method is assumed to be from code,
  #
  # and everything else is assumed to be in-memory scalars.
  #
  if ( exists $config->{native} and defined $config->{native} ) {
    if ( 'filemungeapi' eq $config->{native} ) {    # The API as proposed by Kentnl
      if ( $file->can('munge') ) {
        return $file->munge( $config->{via} );
      }
    }
  }
  if ( $file->can('code') ) {
    return _fromcode_munge( $file, $config );
  }
  return _scalar_munge( $file, $config );
}


































sub munge_files {
  my ( $array, $config ) = @_;
  for my $file ( @{$array} ) {
    return unless munge_file( $file, $config );
  }
  return 1;
}

sub _error {
  my ( undef, %config ) = @_;
  require Carp;
  return Carp::croak( $config{message} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::SimpleMunge - Make munging File::FromCode and File::InMemory easier.

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

  use Dist::Zilla::Util::SimpleMunge qw( auto_munge_file );
  ...;

  sub somesub {
    ...;

    next if $file->is_bytes;

    if ( $file->can('code') ) {

    auto_munge_file $file_from_zilla, sub {
        my ( $file, $content , $encoding ) = @_;
        return $mangled if $encoding ne 'text'; # bytes or text
        ... mangle $content here ...;
        return $mangled;
    };
  }

=head1 DESCRIPTION

=head2 NOTE: STOPGAP

This module is mostly a stopgap and a implementation experiment in lieu of something better in Dist::Zilla eventually transpiring.

=head2 BASIC USAGE

Munging files in Dist::Zilla can be a pain.

Its mostly the same:

  $file->content( substr( $file->content, 0, 10 ) ); # etc.

Except when you come to C<CodeRef>s, that all changes.

  my $orig_code = $file->code();
  $file->code( sub {
      $file->$orig_code() =~ s/foo/bar/
  });

Which quickly gets messy.

So this module is as simple as I think I can get it without hacking Dist::Zilla directly.

  auto_munge_file $file, sub {
     my ( $thefile, $content, $encoding ) = @_;
  };

The callback will be called as appropriate.

=over 4

=item * C<$content> will contain the content, I<decoded if possible>

=item * C<$encoding> will be either C<text> or C<bytes>, the latter if decoding is not possible.

=item * C<InMemory> will apply the code immediately

=item * C<FromCode> will take your code and create a chained system so your code will be evaluated when the file itself is written out.

=back

And this is the most useful and straight forward interface that doesn't invoke any weird re-blessing magic.

=head2 ADVANCED USAGE

There are a few less simple utilities that may also prove useful.

=over 4

=item * L<< C<munge_InMemory>|/munge_InMemory >> - trusts you know what you're dealing with and munges an C<InMemory> instance via the callback.

=item * L<< C<munge_FromCode>|/munge_FromCode >> - trusts you when you say you have a C<FromCode>, and munges with C<CodeRef> chaining.

=item * L<< C<inplace_replace>|/inplace_replace >> - A bit of magic to replace an object in-place without modifying any containers that point to it and without changing the reference address.

=item * L<< C<to_InMemory>|/to_InMemory >> - returns a C<FromCode> represented as a new C<InMemory> object.

=item * L<< C<to_FromCode>|/to_FromCode >> - returns an C<InMemory> represented as a new C<FromCode> object.

=item * L<< C<inplace_to_InMemory>|/inplace_to_InMemory >> - like C<to_InMemory>, but replaces the object in-place.

=item * L<< C<inplace_to_FromCode>|/inplace_to_FromCode >> - like C<to_FromCode>, but replaces the object in-place.

=item * L<< C<munge_file>|/munge_file >> - combines all of the above behaviors based on configuration values.

=item * L<< C<munge_files>|/munge_files >> - applies a single configuration and callback to a collection of files.

=back

=head1 FUNCTIONS

=head2 C<auto_munge_file>

  # auto_munge_file ( $FILE, $CODEREF )

  auto_munge_file( $zilla_file, sub {
      my ( $file, $content, $encoding ) = @_;
      return $new_content # must still be in form $encoding
  });

=head2 C<to_InMemory>

Given a C<FromCode>, return an equivalent C<InMemory> file, flattening the callback
in the process into simply a string.

  my $in_memory = to_InMemory( $from_code );

=head2 C<to_FromCode>

Given a C<InMemory> or C<OnDisk>, return an equivalent C<FromCode> file, converting the content into a callback that yields that content.

  my $from_code = to_FromCode( $in_memory_or_from_disk );

=head2 C<munge_InMemory>

Munge an C<InMemory> ( or similar ) item using a callback.

  munge_InMemory( $xfile, sub {
    my ( $file, $content, $encoding ) = @_;
     ...
    return $content;
  });

This munging is applied immediately.

=head2 C<munge_FromCode>

Munge a C<FromCode> object by replacing the C<CodeRef> with a new one that yields the former.

  munge_FromCode( $xfile, sub {
    my ( $file, $content, $encoding ) = @_;

    $content =~ s/foo/bar/;

    return $content;
  });

Note: this code is equivalent to:

  my $orig_code = $xfile->code;
  my $encoding  = $xfile->core_return_type;
  $xfile->code( sub {

    my $content = $xfile->$orig_code();

    $content =~ s/a/b/;

    return $content;
  });

=head2 C<inplace_replace>

This is a rather nasty way to replace an Object in place without breaking references held on it.

Consider:

  source = ADDR=0x015 = data = { x => y }
                      = class = Foo

  target = ADDR=0x017 = data = { z => a }
                      = class = Bar

  array  = ADDR=0x016 = data = [ 0x015 ]

Then:

  delete source->{x}
  source->{z} = target->{z}
  bless source, 'Bar'

This should result in:

  source = ADDR=0x015 = data = { z => a }
                      = class = Bar

  target = ADDR=0x017 = data = { z => a }
                      = class = Bar

  array  = ADDR=0x016 = data = [ 0x015 ]

Yes, this is rather nasty to do this, but no good alternatives at the moment :).

  inplace_replace( $original_object, $replacement_object );

This will mirror all the keys from C<$replacement_object> to C<$original_object>, and subsequently
ensure C<$original_object> is C<reblessed> into the class of C<$replacement_object>

=head2 C<inplace_to_FromCode>

Shorthand for

  inplace_replace( $file, to_FromCode($file) );

=head2 C<inplace_to_InMemory>

Shorthand for

  inplace_replace( $file, to_InMemory($file) );

=head2 C<munge_file>

  # munge_file ( $FILE , \%CONFIGURATION )

  munge_file(
    $zilla_file,
    {
      via => sub { ... },
        lazy => $laziness
    }
  );

=head4 $FILE

A L<< C<::Role::File> |Dist::Zilla::Role::File >> object to munge.

=head4 %CONFIGURATION

  {
    via => $CODEREF,
    lazy => $LAZINESS,
  }

=head4 $CODEREF

Called to munge the file itself.

Passed a reference to the L<< C<::Role::File> |Dist::Zilla::Role::File >> instance, and a scalar containing
the contents of that file.

Return new content for the file via C<return>

  sub {
    my ( $file, $content ) = @_ ;
    ...;
    return $newcontent;
  }

=head4 $LAZINESS

Specify how lazy you want the munge to be performed. Normally, what this is set to is dependent on the type of file
being munged.

  $LAZINESS = undef ;  # use default for the file type
  $LAZINESS = 0     ;  # Munge immediately
  $LAZINESS = 1     ;  # Defer munging till as late as possible.

For things that are normally backed by scalar values, such as L<< C<::File::OnDisk> |Dist::Zilla::File::OnDisk >> and
L<< C<::File::InMemory> |Dist::Zilla::File::InMemory >>, the laziness is equivalent to C< $LAZINESS = 0 >, which is not lazy at all, and
munges the file content immediately.

For things backed by code, such as L<< C<::File::FromCode> |Dist::Zilla::File::FromCode >>, munging defaults to C< $LAZINESS = 1 >, where the
actual munging sub you specify is executed as late as possible.

You can specify the C< $LAZINESS > value explicitly if you want to customize the behavior, i.e.: Make something that
is presently a scalar type get munged as late as possible ( converting the file into a C<FromCode> file ), or make
something currently backed by code get munged "now", ( converting the file into a C<InMemory> file )

=head2 munge_files

This is mostly a convenience utility for munging a lot of files without having to hand-code the looping logic.

It basically just proxies for L</munge_file>.

  # munge_files ( \@FILEARRAY , \%CONFIGURATION )

  munge_files( [ $zilla_file_one, $zilla_file_two, ], {
    via => sub { ... },
    lazy => $laziness,
  });

=head4 @FILEARRAY

An C<ArrayRef> of L</$FILE>

=head4 See Also

=over 4

=item * L</%CONFIGURATION>

=item * L</$CODEREF>

=item * L</$FILE>

=item * L</$LAZINESS>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
