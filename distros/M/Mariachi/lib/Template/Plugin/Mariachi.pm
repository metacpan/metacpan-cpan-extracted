use strict;
package Template::Plugin::Mariachi;
use URI::Find::Schemeless::Stricter;
use Email::Find;
use Carp qw(croak);

use base qw(Template::Plugin::Filter);

our $FILTER_NAME = "mariachi";

=head1 NAME

Template::Plugin::Mariachi - gussy up email for the Mariachi mailing list archiver

=head1 SYNOPSIS

  [% USE Mariachi %]

  <b>From:</b> [% message.from | mariachi(uris => 0) %]<br />
  <b>Subject:</b> [% message.subject | html | mariachi %]<br />
  <b>Date:</b> [% date.format(message.epoch_date) %]<br />

  <pre>[% message.body | html | mariachi %]</pre>

=head1 DESCRIPTION

Used by the mariachi mailing list archiver to make emails more
suitable for display as html by hiding email addresses and turning
bare urls into links.

Theoretically this could be done with some other C<Template::Toolkit>
plugins but this is easier for us.

=head1 METHODS

=head2 [% USE Mariachi %]

Initialise the Mariahci filter in your template. Can take options like so:

    [% USE Mariachi( uris => 0, email => 1) %]

which, in this case, turns off uri munging and turns on email munging.

Both options are on by default.

=cut

sub init {
    my ($self,@args)  = @_;
    my $config = (ref $args[-1] eq 'HASH')? pop @args : {};

    $self->{_DYNAMIC}   = 1;
    $self->{_MYCONFIG}  = $config;

    $self->install_filter($FILTER_NAME);

    return $self;
}

=head2 [% FILTER mariachi %]

=head2 [% somevar | mariachi %]

Filter some text. Can take options in a similar manner to initialisation.

    [% FILTER mariachi(email => 0) %]

    [% somevar | mariachi(uris => 0) %]


=cut

# possibly extraneous cargo culting but it works so ...
sub filter {
    my ($self, $text, @args) = @_;
    my $config = (ref $args[-1] eq 'HASH')? pop @args : {};

    if ($self->_should_do('email', $config)) {
        find_emails($text, \&munge_email);
    }

    if ($self->_should_do('uris', $config)) {
        URI::Find::Schemeless::Stricter->new(\&munge_uri)->find(\$text);
    }

    if ($self->_should_do('quoting', $config)) {
        munge_quoting(\$text);
    }

    return $text;
}


sub _should_do {
    my $self   = shift;
    my $key    = shift || croak("Must pass a key");
    my $config = shift || {};

    # if it's defined in the local config then use that value
    return $config->{$key}             if defined $config->{$key};
    # otherwise check in the initialised config
    return $self->{_MY_CONFIG}->{$key} if defined $self->{_MY_CONFIG}->{$key};

    # otherwise we're on by default
    return 1;
}


=head2 munge_quoting <text_ref>

Takes a reference to some text and returns it munged for quoting

=cut


sub munge_quoting {
    my $textref = shift;

    $$textref =~ s!^(\s*&gt;.+)$!<i>$1</i>!gm;
}

=head2 munge_email <email> <orig_email>

Takes exactly the same options as callbacks to
C<Email::Find>. Currently turns all non period characters in the
domain part of an email address and turns them into 'x's such that :

 simon@thegestalt.org

becomes

 simon@xxxxxxxxxx.xxx

Should be overridden if you want different behaviour.

=cut

sub munge_email {
    my ($email, $orig_email) = @_;

    $orig_email =~ s{
                     \@(.+)$                    # everything after the '@'
                    }{
                     "@".
                     join '.',                  # join together with dots
                       map { "x" x length($_) } # make each part into 'x's
                         split /\./, $1         # split stuff apart on dots
                     }ex;

    return $orig_email;
}

=head2 munge_uri <uri> <orig_uri>

Takes exactly the same options as callbacks to C<URI::Find> although
it actually uses C<URI::Find::Schemeless::Stricter>.

As such you should be wary if overriding that the uri may not have a
scheme. This

 $uri->scheme('http') unless defined $uri->scheme;

solves that particular problem (for various values of solve)

Currently just turns uris into simple clickable links

 www.foo.com

becomes

 <a href="http://www.foo.com">www.foo.com</a>


Should be overridden if you want different behaviour.

=cut


sub munge_uri {
    my ($uri,$orig_uri) = @_;
    $uri->scheme('http') unless defined $uri->scheme();

    return "<a href='$uri'>$orig_uri</a>";
}

1;

__END__

=head1 TODO

Strip html out of html mails?

Defang javascript and display html in line?

=head1 COPYING

Copyright 2003, the Siesta Development Team

=head1 SEE ALSO

L<URI::Find::Schemeless::Stricter>, L<Email::Find>

=cut
