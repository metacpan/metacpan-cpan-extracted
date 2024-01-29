## no critic: Modules::RequireFilenameMatchesPackage
package
    HashDataRole::Sample::DeNiro;

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

around new => sub {
    my $orig = shift;
    $orig->(@_, separator => '::');
};

package HashData::Sample::DeNiro;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'HashDataRoles-Standard'; # DIST
our $VERSION = '0.003'; # VERSION

with 'HashDataRole::Source::LinesInDATA';
with 'HashDataRole::Sample::DeNiro';

1;
# ABSTRACT: Movies of Robert De Niro with their year

=pod

=encoding UTF-8

=head1 NAME

HashDataRole::Sample::DeNiro - Movies of Robert De Niro with their year

=head1 VERSION

This document describes version 0.003 of HashDataRole::Sample::DeNiro (from Perl distribution HashDataRoles-Standard), released on 2024-01-15.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashDataRoles-Standard>.

=head1 SEE ALSO

L<ArrayData::Sample::DeNiro>

L<TableData::Sample::DeNiro>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
Greetings::1968
Bloody Mama::1970
Hi,Mom!::1970
Born to Win::1971
Mean Streets::1973
Bang the Drum Slowly::1973
The Godfather,Part II::1974
The Last Tycoon::1976
Taxi Driver::1976
1900::1977
New York,New York::1977
The Deer Hunter::1978
Raging Bull::1980
True Confessions::1981
The King of Comedy::1983
Once Upon a Time in America::1984
Falling in Love::1984
Brazil::1985
The Mission::1986
Dear America: Letters Home From Vietnam::1987
The Untouchables::1987
Angel Heart::1987
Midnight Run::1988
Jacknife::1989
We're No Angels::1989
Awakenings::1990
Stanley & Iris::1990
Goodfellas::1990
Cape Fear::1991
Mistress::1991
Guilty by Suspicion::1991
Backdraft::1991
Thunderheart::1992
Night and the City::1992
This Boy's Life::1993
Mad Dog and Glory::1993
A Bronx Tale::1993
Mary Shelley's Frankenstein::1994
Casino::1995
Heat::1995
Sleepers::1996
The Fan::1996
Marvin's Room::1996
Wag the Dog::1997
Jackie Brown::1997
Cop Land::1997
Ronin::1998
Great Expectations::1998
Analyze This::1999
Flawless::1999
The Adventures of Rocky & Bullwinkle::2000
Meet the Parents::2000
Men of Honor::2000
The Score::2001
15 Minutes::2001
City by the Sea::2002
Analyze That::2002
Godsend::2003
Shark Tale::2004
Meet the Fockers::2004
The Bridge of San Luis Rey::2005
Rent::2005
Hide and Seek::2005
The Good Shepherd::2006
Arthur and the Invisibles::2007
Captain Shakespeare::2007
Righteous Kill::2008
What Just Happened?::2008
Everybody's Fine::2009
Machete::2010
Little Fockers::2010
Stone::2010
Killer Elite::2011
New Year's Eve::2011
Limitless::2011
Silver Linings Playbook::2012
Being Flynn::2012
Red Lights::2012
Last Vegas::2013
The Big Wedding::2013
Grudge Match::2013
Killing Season::2013
The Bag Man::2014
Joy::2015
Heist::2015
The Intern::2015
Dirty Grandpa::2016
Hands of Stone::2016
The Comedian::2016
The Wizard of Lies::2017
Joker::2019
The Irishman::2019
The War with Grandpa::2020
The Comeback Trail::2020
Amsterdam::2022
Savage Salvation::2022
Killers of the Flower Moon::2023
About My Father::2023
Ezra::2023
