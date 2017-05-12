package File::PackageIndexer::PPI::ClassXSAccessor;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';


# The Class::XSAccessor special case
sub handle_class_xsaccessor {
  my $indexer = shift;
  my $statement = shift;
  my $curpkg = shift;
  my $pkgs = shift;

  my @subs;
  my $class = defined($curpkg) ? $curpkg->{name} : $indexer->default_package;
  my $started = 0;
  my $state = "key";
  my $key;
  my @tokens = $statement->schildren();
  pop @tokens; # remove ;

  while (@tokens) {
    my $token = shift @tokens;
    next if $token->class eq 'PPI::Token::Whitespace';
    $started = 1, next if not $started and $token->content =~ /^Class::XSAccessor(?:::Array)?$/;
    next if not $started;

    # handle embedded ()'s
    if ($token->isa("PPI::Structure::List")) {
      my @t = $token->schildren;
      foreach my $t (@t) {
        unshift @tokens, ($t->isa("PPI::Statement::Expression") ? $t->schildren() : $t);
      }
      next;
    }

    if ($state eq 'key') {
      my $keyname = File::PackageIndexer::PPI::Util::get_keyname($token);
      return() if not defined $keyname; # broken usage?
      $key = $keyname;
      $state = 'comma';
    }
    elsif ($state eq 'comma') {
      return() unless $token->isa("PPI::Token::Operator");
      last if $token->content eq ';';
      return() unless $token->content =~ /^(?:,|=>)$/; # are there other valid comma-likes?
      $state = defined($key) ? 'value' : 'key';
    }
    elsif ($state eq 'value') {
      if ($key eq 'class') {
        $class = $token->isa("PPI::Token::Quote") ? $token->string : $token->content;
      }
      elsif ($key =~ /^(?:chained|replace)$/) {
        # option, do nothing
      }
      elsif ($token->isa("PPI::Structure::Constructor")) {
        my $struct = File::PackageIndexer::PPI::Util::constructor_to_structure($token);
        if ($struct and ref($struct) eq 'ARRAY') {
          push @subs, @$struct;
        }
        elsif ($struct and ref($struct) eq 'HASH') {
          push @subs, keys %$struct;
        }
      }
      elsif ($token->isa("PPI::Token::Quote")) {
        push @subs, $token->string;
      }
      $key = undef;
      $state = 'comma';
    } # end if value

  } # end while tokens

  my $pkg = $indexer->lazy_create_pkg($class, $pkgs);
  my $subs = $pkg->{subs};
  $pkg->{subs}{$_} = 1 for @subs;
  return();
}



1;

__END__

=head1 NAME

File::PackageIndexer::PPI::ClassXSAccessor - Parse the generated subs from Class::XSAccessor

=head1 DESCRIPTION

No user-serviceable parts inside.

=head1 SEE ALSO

L<File::PackageIndexer>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
