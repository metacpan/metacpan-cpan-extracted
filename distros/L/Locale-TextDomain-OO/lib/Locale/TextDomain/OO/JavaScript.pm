package Locale::TextDomain::OO::JavaScript; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '1.017';

1;

__END__

=head1 NAME

Locale::TextDomain::OO::JavaScript - How to use the JavaScript part

$Id: JavaScript.pm 573 2015-02-07 20:59:51Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/JavaScript.pm $

=head1 VERSION

1.017

=head1 DESCRIPTION

This module provides a high-level interface to JavaScript message translation.

Creating the Lexicon and the selection of the language are server (Perl) based.
The script gets the lexicon in a global variable
named localeTextDomainOOLexicon.

Inside of the constructor is a language attribute,
that shoud be filled from server.

It is possible to filter the lexicon.
For bigger lexicon files filter also by language to split the lexicon.
Load only the lexicon of the current language.

=head2 How to extract?

Use module Locale::TextDomain::OO::Extract.
This is a base class for all source scanner to create pot files.
Use this base class and give this module the rules
or use one of the already exteded classes.
Locale::TextDomain::OO::Extract::JavaScript::JS
is a extension for Javacript from *.js files and so on.

=head1 SYNOPSIS

Inside of this distribution is a directory named javascript.
Copy this files into your project.
Do the same with javascript files of
L<Locale::TextDomain::OO::Util::Constants|Locale::TextDomain::OO::Util::Constants>,
L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>
and L<Locale::Utils::PlaceholderNamed|Locale::Utils::PlaceholderNamed>.

This scripts depending on L<http://jquery.com/>.

Watch also the javascript/Example.html how to use.

    <!-- depends on -->
    <script type="text/javascript" src=".../jquery-...js"></script>
    <script type="text/javascript" src=".../Locale/TextDomain/OO/Util/Constants.js"></script>
    <script type="text/javascript" src=".../Locale/TextDomain/OO/Util/JoinSplitLexiconKeys.js"></script>
    <script type="text/javascript" src=".../Locale/Utils/PlaceholderNamed.js"></script>

    <!-- stores the lexicon into var localeTextDomainOOLexicon -->
    <script type="text/javascript" src=".../localeTextDomainOOLexicon.js"></script>

    <!-- depends on var localeTextDomainOOLexicon -->
    <script type="text/javascript" src=".../Locale/TextDomain/OO.js"></script>
    <script type="text/javascript" src=".../Locale/TextDomain/OO/Plugin/Expand/Gettext/Loc.js"></script>
    <script type="text/javascript" src=".../Locale/TextDomain/OO/Plugin/Expand/Gettext/Loc/DomainAndCategory.js"></script>

    <!-- initialize -->
    <script type="text/javascript">
        var ltdoo = new localeTextDomainOO({
            plugins  : [ 'localeTextDomainOOExpandGettextLocDomainAndCategory' ],
            language : '@{[ $language_tag ]}', // from Perl
            category : 'LC_MESSAGES', // optional category
            domain   : 'MyDomain', // optional domain
                filter   : function(translation) { // optional filter
                // modifies the translation late
                return translation;
            },
            logger   : function (message, argMap) { // optional logger
                console.log(message);
                return;
            }
        });
    </script>

This configuration would be use Lexicon "$language_tag:LC_MESSAGES:MyDomain".
That lexicon should be filled with data.

    <!-- translations -->
    <script type="text/javascript">
        // extractable, translate
        str = ltdoo.loc_('msgid');
        str = ltdoo.loc_x('msgid', {key1 : 'value1'});
        str = ltdoo.loc_p('msgctxt', 'msgid');
        str = ltdoo.loc_px('msgctxt', 'msgid', {key1 : 'value1'});
        str = ltdoo.loc_n('msgid', 'msgid_plural', count);
        str = ltdoo.loc_nx('msgid', 'msgid_plural', count, {key1 : 'value1'});
        str = ltdoo.loc_np('msgctxt', 'msgid', 'msgid_plural', count);
        str = ltdoo.loc_npx('msgctxt', 'msgid', 'msgid_plural', count, {key1 : 'value1'});

        // extractable, prepare
        arr = ltdoo.Nloc_('msgid');
        arr = ltdoo.Nloc_x('msgid', {key1 : 'value1'});
        arr = ltdoo.Nloc_p('msgctxt', 'msgid');
        arr = ltdoo.Nloc_px('msgctxt', 'msgid', {key1 : 'value1'});
        arr = ltdoo.Nloc_n('msgid', 'msgid_plural', count);
        arr = ltdoo.Nloc_nx('msgid', 'msgid_plural', count, {key1 : 'value1'});
        arr = ltdoo.Nloc_np('msgctxt', 'msgid', 'msgid_plural', count);
        arr = ltdoo.Nloc_npx('msgctxt', 'msgid', 'msgid_plural', count, {key1 : 'value1'});

        // with domain

        // extractable, translate
        str = ltdoo.loc_d('domain', 'msgid');
        str = ltdoo.loc_dx('domain', 'msgid', {key1 : 'value1'});
        str = ltdoo.loc_dp('domain', 'msgctxt', 'msgid');
        str = ltdoo.loc_dpx('domain', 'msgctxt', 'msgid', {key1 : 'value1'});
        str = ltdoo.loc_dn('domain', 'msgid', 'msgid_plural', count);
        str = ltdoo.loc_dnx('domain', 'msgid', 'msgid_plural', count, {key1 : 'value1'});
        str = ltdoo.loc_dnp('domain', 'msgctxt', 'msgid', 'msgid_plural', count);
        str = ltdoo.loc_dnpx('domain', 'msgctxt', 'msgid', 'msgid_plural', count, {key1 : 'value1'});

        // extractable, prepare
        arr = ltdoo.Nloc_d('domain', 'msgid');
        arr = ltdoo.Nloc_dx('domain', 'msgid', {key1 : 'value1'});
        arr = ltdoo.Nloc_dp('domain', 'msgctxt', 'msgid');
        arr = ltdoo.Nloc_dpx('domain', 'msgctxt', 'msgid', {key1 : 'value1'});
        arr = ltdoo.Nloc_dn('domain', 'msgid', 'msgid_plural', count);
        arr = ltdoo.Nloc_dnx('domain', 'msgid', 'msgid_plural', count, {key1 : 'value1'});
        arr = ltdoo.Nloc_dnp('domain', 'msgctxt', 'msgid', 'msgid_plural', count);
        arr = ltdoo.Nloc_dnpx('domain', 'msgctxt', 'msgid', 'msgid_plural', count, {key1 : 'value1'});

        // with category

        // extractable, translate
        str = ltdoo.loc_c('msgid', 'category');
        str = ltdoo.loc_cx('msgid', 'category', {key1 : 'value1'});
        str = ltdoo.loc_cp('msgctxt', 'msgid', 'category');
        str = ltdoo.loc_cpx('msgctxt', 'msgid', 'category', {key1 : 'value1'});
        str = ltdoo.loc_cn('msgid', 'msgid_plural', count, 'category');
        str = ltdoo.loc_cnx('msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});
        str = ltdoo.loc_cnp('msgctxt', 'msgid', 'msgid_plural', count, 'category');
        str = ltdoo.loc_cnpx('msgctxt', 'msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});

        // extractable, prepare
        arr = ltdoo.Nloc_c('msgid', 'category');
        arr = ltdoo.Nloc_cx('msgid', 'category', {key1 : 'value1'});
        arr = ltdoo.Nloc_cp('msgctxt', 'msgid', 'category');
        arr = ltdoo.Nloc_cpx('msgctxt', 'msgid', 'category', {key1 : 'value1'});
        arr = ltdoo.Nloc_cn('msgid', 'msgid_plural', count, 'category');
        arr = ltdoo.Nloc_cnx('msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});
        arr = ltdoo.Nloc_cnp('msgctxt', 'msgid', 'msgid_plural', count, 'category');
        arr = ltdoo.Nloc_cnpx('msgctxt', 'msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});

        // with domain and category

        // extractable, translate
        str = ltdoo.loc_dc('domain', 'msgid', 'category');
        str = ltdoo.loc_dcx('domain', 'msgid', 'category', {key1 : 'value1'});
        str = ltdoo.loc_dcp('domain', 'msgctxt', 'msgid', 'category');
        str = ltdoo.loc_dcpx('domain', 'msgctxt', 'msgid', 'category', {key1 : 'value1'});
        str = ltdoo.loc_dcn('domain', 'msgid', 'msgid_plural', count, 'category');
        str = ltdoo.loc_dcnx('domain', 'msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});
        str = ltdoo.loc_dcnp('domain', 'msgctxt', 'msgid', 'msgid_plural', count, 'category');
        str = ltdoo.loc_dcnpx('domain', 'msgctxt', 'msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});

        // extractable, prepare
        arr = ltdoo.Nloc_dc('domain', 'msgid', 'category');
        arr = ltdoo.Nloc_dcx('domain', 'msgid', 'category', {key1 : 'value1'});
        arr = ltdoo.Nloc_dcp('domain', 'msgctxt', 'msgid', 'category');
        arr = ltdoo.Nloc_dcpx('domain', 'msgctxt', 'msgid', 'category', {key1 : 'value1'});
        arr = ltdoo.Nloc_dcn('domain', 'msgid', 'msgid_plural', count, 'category');
        arr = ltdoo.Nloc_dcnx('domain', 'msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});
        arr = ltdoo.Nloc_dcnp('domain', 'msgctxt', 'msgid', 'msgid_plural', count, 'category');
        arr = ltdoo.Nloc_dcnpx('domain', 'msgctxt', 'msgid', 'msgid_plural', count, 'category', {key1 : 'value1'});
    </script>

=head1 SUBROUTINES/METHODS

see SYNOPSIS

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<http://jquery.com/>

L<Locale::TextDomain::OO::Util::Constants|Locale::TextDomain::OO::Util::Constants>

L<Locale::TextDomain::OO::Util::JoinSplitLexiconKeys|Locale::TextDomain::OO::Util::JoinSplitLexiconKeys>

L<Locale::Utils::PlaceholderNamed|Locale::Utils::PlaceholderNamed>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
