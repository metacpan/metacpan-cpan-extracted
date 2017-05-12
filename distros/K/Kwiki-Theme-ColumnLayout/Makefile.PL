
use inc::Module::Install;

name            ('Kwiki-Theme-ColumnLayout');
abstract        ('Provide Two/Three-column layout Kwiki Theme');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Kwiki/Theme/ColumnLayout.pm');
requires        ('Kwiki');
requires        ('Kwiki::ConfigBlocks');
requires        ('Kwiki::Infobox');
requires        ('Kwiki::NavigationToolbar');

&WriteAll;

