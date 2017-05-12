package HTTP::Cookies::Guess;
use strict;
use Carp qw(carp croak);
use UNIVERSAL::require;

our $VERSION = '0.01';

sub create {
    my $class = shift;
    my %opt = @_ > 1 ? @_ : (file => $_[0]);

    croak 'Please set option for cookie file path.' unless $opt{file};
    unless ($opt{type}) {
        my $guess = $class->auto_guess($opt{file});
        $guess->{type} ? ($opt{type} = $guess->{type}) : (%opt = %{ $guess });
    }

    my $type = delete $opt{type};
    my $impl = $type ? "HTTP::Cookies::$type" : "HTTP::Cookies";
    $impl->require or return croak "Error loading $impl: $@";
    $impl->new(%opt);
}

sub auto_guess {
    my($self, $filename) = @_;

    # autosave is off by default for foreign cookies files

    if ($filename =~ /cookies\.txt$/i) {
        return { type => 'Mozilla', file => $filename };
    } elsif ($filename =~ /index\.dat$/i) {
        return { type => 'Microsoft', file => $filename };
    } elsif ($filename =~ /Cookies\.plist$/i) {
        return { type => 'Safari', file => $filename };
    } elsif ($filename =~ m!\.w3m/cookie$!) {
        return { type => 'w3m', file => $filename };
    }

    carp ("Don't know type of $filename. Use it as LWP default");
    return { file => $filename, autosave => 1 };
}

1;

__END__

=head1 NAME

HTTP::Cookies::Guess - Guesses UserAgent from file name.

=head1 SYNOPSIS

  use HTTP::Cookies::Guess;
  $cookie_jar = HTTP::Cookies::Guess->create('/home/user/.w3m/cookie');
  $cookie_jar = HTTP::Cookies::Guess->create(file => '/home/user/.w3m/cookie');
  $cookie_jar = HTTP::Cookies::Guess->create(file => '/home/user/.w3m/cookie'i, type => 'w3m');

  $cookie_jar = HTTP::Cookies::Guess->create(file => '/home/user/cookies.txt'); # mozilla

=head1 DESCRIPTION

HTTP::Cookies::Guess is a factory class to create HTTP::Cookies subclass
instances by detecting the proper subclass using its filename (and
possibly magic, if the filename format is share amongst multiple
subclasses, eventually).

L<HTTP::Cookies::Guess> is split/rewrite module by Yappo from L<Plagger::Cookies> module by miyagawa.

=head1 AUTHOR

Tatsuhiko Miyagawa, Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Cookies>, L<Plagger::Cookies>,
L<HTTP::Cookies::Mozilla>, L<HTTP::Cookies::Microsoft>, L<HTTP::Cookies::Netscape>
L<HTTP::Cookies::Safari>, L<HTTP::Cookies::w3m>, L<HTTP::Cookies::Omniweb>, L<HTTP::Cookies::iCab>

=cut
