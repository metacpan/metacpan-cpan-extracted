package Locale::TextDomain::OO::Extract; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '2.015';

1;

__END__

=head1 NAME
Locale::TextDomain::OO::Extract - Extracts internationalization data

$Id: Extract.pm 719 2018-09-21 12:58:00Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract.pm $

=head1 VERSION

2.015

=head1 DESCRIPTION

This module extracts internationalization data.

The extractor runs the following steps:

=over 4

=item preprocess the file

=item find all possible positions in content

=item match exactly and create a stack

=item map the stack to a lexicon entry

=back

If you want to write the lexicon structure to pot files
see folder example of this distribution how it works.

=head1 SYNOPSIS

There are different extract module for different files.
All this extracted data are stored into one or selective lexicons.
At the end of extraction this lexicons
can be stored into pot files or anywhere else.

=head2 Use an existing extractor

    use strict;
    use warnings;
    use Locale::TextDomain::OO::Extract::...;
    use Path::Tiny qw(path);

    my $extractor = Locale::TextDomain::OO::Extract::...->new(
        # all parameters are optional
        lexicon_ref => \my %lexicon,  # default is {}
        domain      => 'MyDomain',    # default is q{}
        category    => 'LC_MESSAGES', # default is q{}
        debug_code  => sub {          # default is undef
            my ($group, $message) = @_;
            print $group, ', ', $message, "\n";
            return;
        },
    );

    my @files = (
        'relative_dir/filename1.suffix',
        'relative_dir/filename2.suffix',
    );
    for ( @files ) {
        $extractor->clear;
        $extractor->filename($_);
        $extractor->content_ref( \( path($_)->slurp_utf8 ) );
        $extractor->extract;
    }

    # do something with that
    # maybe write a pot file using Locale::PO
    ... = extractor->lexicon_ref;

=head2 Write your own extractor

    package MyExtractor;

    use Moo;

    extends qw(
        Locale::TextDomain::OO::Extract::Base::RegexBasedExtractor
    );
    with qw(
        Locale::TextDomain::OO::Extract::Role::File
    );

Optional method to uncomment or interpolate the file content or anything else.

    sub preprocess {
        my $self = shift;

        my $content_ref = $self->content_ref;
        # modify anyhow
        ${$content_ref}=~ s{\\n}{\n}xmsg;

        return;
    }

Map the reference, all the matches or defaults.
See Perl extractor how it works.
Maybe ignore some stack entries.

    sub stack_item_mapping {
        my $self = shift;

        my $match = $_->{match};
        $self->add_message({
            reference    => ...,
            domain       => ...,
            category     => ...,
            msgctxt      => ...,
            msgid        => ...,
            msgid_plural => ...,
        });

        return;
    }

Match all positions, the searched string is starting with.
You can match to the end of the searched string but there is no need for.

    my $start_rule = qr{ ... }xms;

Match exactly the different things.
All the values from () are stored in stack.
Prepare the stack in a way you are able to merge the data.
Maybe an empty match helps to have all on the right position.

'or' means: if not then try the following.
'or' is only allowed between 2 array references.

    my $rules = [
        [
            'begin',
            qr{ ... ( ... ) ...}xms, # match this
            'and',
            qr{ ... ( ... ) ...}xms, # then that
            'end',
        ]
        'or',
        [
            'begin',
            [
                qr{ ... ( ... ) ... }xms,
            ],
            'or',
            [
                qr{ ... ( ... ) ... }xms,
                'or',
                qr{ ... ( ... ) ... }xms,
            ],
            'end',
        ],
    ];

Tell your extractor what steps he should run.

    sub extract {
        my $self = shift;

        $self->start_rule($start_rule);
        $self->rules($rules);
        $self->preprocess;
        $self->SUPER::extract;
        for ( @{ $self->stack } ) {
            $self->stack_item_mapping;
        }

        return;
    }

=head2 The whole process (extract, translate, clean, format)

See also module
L<Locale::TextDomain::OO::Extract::Process|Locale::TextDomain::OO::Extract::Process>

 1.1. If the PO file not exists for a language create it with the right header
      or change the defaults after initial write (spew).
        |
        |     .------------------------------------.
        |     |                                    |
        v     v                                    |
    .-------------.                                |
    |    de.po    |-.                              |
    '-------------' |                              |
      '-------------'                              |
        |         |                                |
 .------'   2.1. Read the existing PO files        |
 |               of all languages                  |
 |               into the lexicon sturcture.       |
 |                |                                |
 |                v                                |
 |   .-------------------.                         |
 |   | lexicon structure |<--------------------.   |
 |   | de:: fr:: ...     |<----------------.   |   |
 |   '-------------------'                 |   |   |
 |       |       |   |                     ^   ^   ^
 |       |       |   '-------------------->|->-|->-|->-.
 |       |       |                         ^   ^   ^   |
 |       |   3.1. Remove all gettext       |   |   |   |
 |       |        references               |   |   |   |
 |       |       |                         |   |   |   |
 |       |       '-------------------------'   |   |   |
 |       |                                     |   |   |
 |       |   .------------------.              |   |   |
 |       |   | MyProjectFile.pm |-.            |   |   |
 |       |   '------------------' |            |   |   |
 |       |     '------------------'            |   |   |
 |       |              |                      |   |   |
 |       |   4. Extract the files              |   |   |
 |       |      of your project.               |   |   |
 |       |   4.1. Add new message id's         |   |   |
 |       |        if not already exists.       |   |   |
 |       |   4.2. Add the new references.      |   |   |
 |       |              |                      |   |   |
 |       |              '----------------------'   |   |
 |       |                                         |   |
 |   5.1. Merge new and changed messages.          |   |
 |   5.2. Write back the PO files.                 |   |
 |       |                                         ^   |
 |       '---------------------------------------->O   |
 v                                                 ^   |
 O->-----.                                         |   |
 v       |                                         |   |
 |   6.1. Translate the PO files.                  |   |
 |       |                                         ^   |
 |       '---------------------------------------->O   |
 v                                                 ^   |
 O->-----.                                         |   |
 v       |                                         |   |
 |   7.1. Clean all messages                       |   |
 |        without any reference.                   |   |
 |       |                                         |   |
 |       '-----------------------------------------'   |
 |                                                     |
 '-------.                                             |
         |                                             |
     8.1. Write MO files.                              |
         |                                             |
         v                                             |
 .-------------.                                       |
 |    de.mo    |-.                                     |
 '-------------' |                                     |
   '-------------'                                     |
                                                       |
 Update the references in region files.                |
                                                       |
 1.2. If the PO file not exists for a region           |
      create it with the right header.                 |
            |                                          |
            v                                          |
     .----------.                                      |
     | de-at.po |-.                                    v
     '----------' |<-----------------------------------O
       '----------'                                    ^
          |   |                                        |
 .--------'   |                                        |
 |            |                                        |
 |   2.1. Read the existing PO files                   |
 |        of all regions                               |
 |        into the lexicon sturcture.                  |
 |   3.2. Remove all references.                       |
 |   4.3. Add the new references (from language)       |
 |        for existing region messages only.           |
 |   5.1. Merge changed messages.                      |
 |   5.2. Write back to PO files.                      |
 |   6.2. Translate the PO files.                      |
 |   7.2. Clean all messages                           |
 |        without any reference.                       |
 |             |                                       |
 |             '---------------------------------------'
 '--------.
          |
 8.2. Write MO files.
          |
          v
     .----------.
     | de-at.mo |-
     '----------' |
       '----------'

=head1 SUBROUTINES/METHODS

none

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

none

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

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
