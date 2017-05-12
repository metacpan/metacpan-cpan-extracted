package Locale::Maketext::Utils::Mock;

use strict;
use warnings;
use Locale::Maketext::Utils ();    # brings in Locales.pm
use base 'Locale::Maketext::Utils';

$Locale::Maketext::Utils::Mock::VERSION = '0.1';

package Locale::Maketext::Utils::Mock::en;
use base 'Locale::Maketext::Utils::Mock';
our %Lexicon;

package Locale::Maketext::Utils::Mock;

our %Lexicon;

sub init_mock_locales {
    my $cnt = 0;
    for my $loc_tag ( map { Locales::normalize_tag($_) } @_ ) {
        next if !$loc_tag;
        next unless $loc_tag =~ m/^i_/ || Locales->new($loc_tag);

        $cnt++;
        eval "package Locale::Maketext::Utils::Mock::$loc_tag;use base 'Locale::Maketext::Utils::Mock';our \%Lexicon;package Locale::Maketext::Utils::Mock;";
        if ($@) {
            $cnt--;
            require Carp;
            Carp::carp($@);
        }

    }

    return $cnt;
}

sub create_method {
    my ( $class, $def_hr ) = @_;
    if ( @_ == 2 ) {
        $class = ref($class) if ref($class);
    }
    else {
        $def_hr = $class;                            # was a function call
        $class  = 'Locale::Maketext::Utils::Mock';
    }
    return if ref($def_hr) ne 'HASH';
    no strict 'refs';
    for my $m ( sort keys %{$def_hr} ) {
        *{ $class . "::$m" } = ref( $def_hr->{$m} ) eq 'CODE' ? $def_hr->{$m} : sub { return "I am $m()." };
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Locale::Maketext::Utils::Mock - mock locale object

=head1 VERSION

This document describes Locale::Maketext::Utils::Mock version 0.1

=head1 SYNOPSIS

    use Locale::Maketext::Utils::Mock;
    my $lh = Locale::Maketext::Utils::Mock->get_handle();

=head1 DESCRIPTION

Often we need to create a class so we can do a Locale::Maketext[::Utils] testing but Locale::Maketext is not designed for direct use. Instead you need to create a class with a lexicon and at least the 'en' subclass of that.

This module does all the work for you and behaves like a typical L<Locale::Maketext::Utils> object.

You can also add additional locales at will.

=head1 INTERFACE

=head2 get_handle()

Requires the L<Locale::Maketext::Utils::Mock> based locale handle.

=head2 init_mock_locales()

If you want more than 'en' you can initialize them using init_mock_locales();

It takes a list of locales tags, passes them through L<Locales::normalize_tag()|Locales/Utility functions> and creates the subclass for each one that can be used to create a L<Locales> object or that is an “i_” tag (e.g. i_yoda).

    use Locale::Maketext::Utils::Mock ();
    Locale::Maketext::Utils::Mock->init_mock_locales('fr', 'it', 'en_gb');
    my $it = Locale::Maketext::Utils::Mock->get_handle('it'); # Locale::Maketext::Utils::Mock::it object.
    my $ja = Locale::Maketext::Utils::Mock->get_handle('js'); # Locale::Maketext::Utils::Mock::en object since there is no 'ja' subclass.

It can be called as a function, a class method, or object method.

It returns the number of subclasses successfully created.

=head2 create_method()

Takes a hashref whose keys are the methods to make for mocked objects.

The values are either a coderef for the method or undef. Undef will result in a coderef that returns “I am $key()”.

    use Locale::Maketext::Utils::Mock ();
    Locale::Maketext::Utils::Mock->create_method({ method_x => undef, method_y => sub { return "YABBA DABBA $_[1]" } });
    my $lh = Locale::Maketext::Utils::Mock->get_handle();
    print $lh->maketext("Blah [method_x] blah [method_y,_1] blah.", 42); $ Blah I am method_x() blah YABBA DABBA 42 blah.

=head1 DIAGNOSTICS

init_mock_locales() carp()s if there was a problem createing the subclass.

=head1 CONFIGURATION AND ENVIRONMENT

Locale::Maketext::Utils::Mock requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Locale::Maketext::Utils>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-locale-maketext-utils-mock@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Depending on need/demand:

1. Add a way to define lexicon for specifical locales.

2. ? ability to create object in it's own class (so subclass modification are separate) ?

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
