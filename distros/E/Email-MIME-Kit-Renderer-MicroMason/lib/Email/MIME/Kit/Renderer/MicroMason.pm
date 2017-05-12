package Email::MIME::Kit::Renderer::MicroMason;

# ABSTRACT: Render parts of your mail with Text::MicroMason

use Moose;
with 'Email::MIME::Kit::Role::Renderer';
use Scalar::Util ();
use Text::MicroMason;
use Carp;

our $VERSION = '1.21';

sub render {
    my ( $self, $content_ref, $stash ) = @_;
    $stash ||= {};

    # Parse the template with Text::MicroMason
    my $outbuf = $self->mason->execute( text => $$content_ref, %$stash );

    return \$outbuf;
}

has mason => (
    is => 'ro',
    ## isa      => 'Text::MicroMason',  # T:MM isa strange subclass
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my ($self) = @_;
        my $mason = Text::MicroMason->new('-Filters', '-MKit');
        $mason->{__mkit_renderer} = $self;
        Scalar::Util::weaken($mason->{__mkit_renderer});
        return $mason;
    },
);

{
  $INC{'Text/MicroMason/MKit.pm'} = 1;
  package Text::MicroMason::MKit;

  sub read_file {
    my ($self, $file) = @_;
    my $text = $self->{__mkit_renderer}->kit->get_kit_entry($file);
    return $$text;
  }
}

no Moose;
1;

__END__

=pod

=head1 NAME

Email::MIME::Kit::Renderer::MicroMason - Render parts of your mail with Text::MicroMason

=head1 VERSION

version 1.21

=head1 SYNOPSIS

To use MicroMason in your mkit use something like:

    {
      "renderer": "MicroMason",
      "header": [
        { "From": "WY Corp <noreplies@wy.example.com" },
        { "To": "<% $ARGS{recruit}->email %>" },
        { "Subject": "Welcome aboard, <% ARGS{recruit}->name %>" }
      ],
      "alternatives": [
        { "type": "text/plain", "path": "body.txt" },
         {
          "type": "text/html",
          "path": "body.html",
          "container_type": "multipart/related",
          "attachments": [ { "type": "image/jpeg", "path": "logo.jpg" } ]
        }
      ]
    }

Then in your email templates (body.txt and body.html) you can do:

    <%args>
    $recruit
    $cid_for
    </%args>

    <& "../includes/header.msn", %ARGS &>

    <p>
    Dear <% $recruit->name %>,
    </p>

    <p>
    Welcome to WY Corp.
    </p>

    <& "../includes/footer.msn", %ARGS &>

EMK::Renderer::MicroMason will try to make any components included with
<& ... &> relative to the mkit directory.

=head1 DESCRIPTION

This renderer for L<Email::MIME::Kit> uses L<Text::MicroMason> to enable
you to write your mkits using basic Mason syntax. See
L<Text::MicroMason::HTMLMason> for details on the syntax.

This is based on L<Text::MicroMason> rather than the full blown L<HTML::Mason>
because L<HTML::Mason> is focused on directories and files and 
L<Email::MIME::Kit> prefers to work with strings. L<Text::MicroMason> 
accommodates this and is a bit smaller than it's big brother.

=head2 METHODS

=over 4

=item render()

    render( $content_ref, $stash )

Called by L<Email::MIME::Kit::Renderer> to parse template strings
($content_ref) with L<Text::MicroMason> and return a plain text string.

=back

=head1 ACKNOWLEGEMENTS

This is basically just Ricardo SIGNES' EMK::Renderer::TestRenderer with
basic integration of L<Text::MicroMason>. Thanks to Ricardo for the
excellent EMK package.

=head1 SEE ALSO

L<Email::MIME::Kit>, L<HTML::Mason>, L<Text::MicroMason>,
and L<Text::MicroMason::HTMLMason>.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
