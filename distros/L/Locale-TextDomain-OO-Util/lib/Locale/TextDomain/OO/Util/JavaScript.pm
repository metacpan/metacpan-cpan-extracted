package Locale::TextDomain::OO::Util::JavaScript; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '4.001';

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Util::JavaScript - How to use the JavaScript part

=head1 VERSION

4.001

$Id: OO.pm 502 2014-05-12 20:19:51Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO.pm $

=head1 SYNOPSIS

Inside of this distribution is a directory named javascript.
For more information see:
L<Locale::TextDomain::OO::JavaScript|Locale::TextDomain::OO::JavaScript>

This script depends on L<http://jquery.com/>.

=head1 DESCRIPTION

This package also contais the utils as JavaScript.

=head1 SUBROUTINES/METHODS

    var constants = new localeTextDomainOOUtilConstants();
    var lexiconKeySeparator = constants.lexiconKeySeparator();
    var pluralSeparator     = constants.pluralSeparator();
    var msgKeySeparator     = constants.msgKeySeparator();

    var keyUtil = new localeTextDomainOOUtilJoinSplitLexiconKeys();
    var lexiconKey = keyUtil.joinLexiconKey({
        'language' : 'de',          // default 'i-default'
        'domain'   : 'test',        // default undefined
        'category' : 'LC_MESSAGES', // default undefined
        'project'  : 'shop'         // default undefined
    });
    var msgKey = keyUtil.joinMessageKey({
        'msgctxt'      : 'context',                   // default undefined
        'msgid'        : 'phrase or singular phrase', // default ''
        'msgid_plural' : 'plural phrase',             // default undefined
    });

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<http://jquery.com/>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<Locale::TextDoamin::OO::JavaScript|Locale::TextDoamin::OO::JavaScript>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 - 2018,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
