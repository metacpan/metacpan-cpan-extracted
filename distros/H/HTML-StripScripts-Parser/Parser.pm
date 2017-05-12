package HTML::StripScripts::Parser;
use strict;

use vars qw($VERSION);
$VERSION = '1.03';

=head1 NAME

HTML::StripScripts::Parser - XSS filter using HTML::Parser

=head1 SYNOPSIS

  use HTML::StripScripts::Parser();

  my $hss = HTML::StripScripts::Parser->new(

       {
           Context => 'Document',       ## HTML::StripScripts configuration
           Rules   => { ... },
       },

       strict_comment => 1,             ## HTML::Parser options
       strict_names   => 1,

  );

  $hss->parse_file("foo.html");

  print $hss->filtered_document;

  OR

  print $hss->filter_html($html);

=head1 DESCRIPTION

This class provides an easy interface to C<HTML::StripScripts>, using
C<HTML::Parser> to parse the HTML.

See L<HTML::Parser> for details of how to customise how the raw HTML is parsed
into tags, and L<HTML::StripScripts> for details of how to customise the way
those tags are filtered.

=cut

=head1 CONSTRUCTORS

=over

=item new ( {CONFIG}, [PARSER_OPTIONS]  )

Creates a new C<HTML::StripScripts::Parser> object.

The CONFIG parameter has the same semantics as the CONFIG
parameter to the C<HTML::StripScripts> constructor.

Any PARSER_OPTIONS supplied will be passed on to the L<HTML::Parser>
init method, allowing you to influence the way the input is parsed.

You cannot use PARSER_OPTIONS to set the C<HTML::Parser> event handlers
(see L<HTML::Parser/Events>) since C<HTML::StripScripts::Parser>
uses all of the event hooks itself.
However, you can use C<Rules> (see L<HTML::StripScripts/Rules>) to customise
the handling of all tags and attributes.

=cut

use HTML::StripScripts;
use HTML::Parser;
use base qw(HTML::StripScripts HTML::Parser);

sub hss_init {
    my ( $self, $cfg, @parser_options ) = @_;

    $self->init(
        @parser_options,

        api_version      => 3,
        start_document_h => [ 'input_start_document', 'self' ],
        start_h          => [ 'input_start', 'self,text' ],
        end_h            => [ 'input_end', 'self,text' ],
        text_h           => [ 'input_text', 'self,text' ],
        default_h        => [ 'input_text', 'self,text' ],
        declaration_h    => [ 'input_declaration', 'self,text' ],
        comment_h        => [ 'input_comment', 'self,text' ],
        process_h        => [ 'input_process', 'self,text' ],
        end_document_h   => [ 'input_end_document', 'self' ],

        # workaround for http://rt.cpan.org/NoAuth/Bug.html?id=3954
        (  $HTML::Parser::VERSION =~ /^3\.(29|30|31)$/
           ? ( strict_comment => 1 )
           : ()
        ),
    );

    $self->SUPER::hss_init($cfg);
}

=back

=head1 METHODS

See L<HTML::Parser> for input methods, L<HTML::StripScripts> for output
methods.

=head2 C<filter_html()>

C<filter_html()> is a convenience method for filtering HTML already loaded
into a scalar variable.  It combines calls to C<HTML::Parser::parse()>,
C<HTML::Parser::eof()> and C<HTML::StripScripts::filtered_document()>.

    $filtered_html = $hss->filter_html($html);


=cut

#===================================
sub filter_html {
#===================================
    my ( $self, $html ) = @_;
    $self->parse($html);
    $self->eof;
    return $self->filtered_document;
}

=head1 SUBCLASSING

The C<HTML::StripScripts::Parser> class is subclassable.  Filter objects
are plain hashes.  The hss_init() method takes the same arguments as
new(), and calls the initialization methods of both C<HTML::StripScripts>
and C<HTML::Parser>.

See L<HTML::StripScripts/"SUBCLASSING"> and L<HTML::Parser/"SUBCLASSING">.

=head1 SEE ALSO

L<HTML::StripScripts>, L<HTML::Parser>, L<HTML::StripScripts::LibXML>

=head1 BUGS

None reported.

Please report any bugs or feature requests to
bug-html-stripscripts-parser@rt.cpan.org, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Original author Nick Cleaton E<lt>nick@cleaton.netE<gt>

New code added and module maintained by Clinton Gormley
E<lt>clint@traveljury.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Nick Cleaton.  All Rights Reserved.

Copyright (C) 2007 Clinton Gormley.  All Rights Reserved.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

