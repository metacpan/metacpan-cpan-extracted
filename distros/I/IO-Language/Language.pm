package IO::Language;

use strict;
use warnings;

use Lingua::Translate;
use IO::Handle;

use vars qw[$VERSION @ISA];

$VERSION = '0.01';
@ISA     = qw[IO::Handle];

sub import {
  my $class = shift;
  my @trans = @_;
  
  if ( @trans < 2 ) {
    require Carp;
    Carp::croak( "Source and destination lanuages not specified" );
  }
  my $translator = Lingua::Translate->new(
                                          src  => $trans[0],
                                          dest => $trans[1],
                                         );
  if ( $translator ) {
    tie *STDOUT => $class, translator => $translator, cache => {};
  } else {
    require Carp;
    Carp::croak( "Initializing translator for $trans[0] -> $trans[1] failed" );
  }
}

sub TIEHANDLE {
  my $class = shift;
  return bless { @_ }, $class;
}

sub PRINT {
  my $self = shift;
  {
    no warnings; untie *STDOUT;
    print STDERR join $, => ( map {
                                   my @string     = split /\n/, $_;
                                   my @new_string = ();
                                   foreach my $string ( @string ) {
                                     push @new_string, $self->{translator}->translate($string);
                                   }
                                   my $new_string = join "\n", @new_string;
                                   if ( /(\n+)$/s ) {
                                     $new_string .= $1;
                                   }
                                   $new_string;
                                  } @_ );
  }
  tie *STDOUT => "IO::Language", %{$self};
}

1;
__END__

=head1 NAME

IO::Language - Perl module for I18N output.

=head1 SYNOPSIS

  use IO::Language en => ja;

  print 'Hello';

=head1 DESCRIPTION

This module will convert your IO operations to a different lanuage.

This is alpha code.

Only C<print> is supported.

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>

=head1 TODO

Yes.

=head1 COPYRIGHT

Copyright (c) 2002 Casey R. West <casey@geeknest.com>.  All
rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1).

=cut
