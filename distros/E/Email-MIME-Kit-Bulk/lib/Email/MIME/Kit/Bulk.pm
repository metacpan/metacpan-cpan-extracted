package Email::MIME::Kit::Bulk;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Email::MIME::Kit-based bulk mailer
$Email::MIME::Kit::Bulk::VERSION = '0.0.3';

use Moose;
use namespace::autoclean;

use Email::MIME;
use Email::MIME::Kit;
use Email::Sender::Simple 'sendmail';
use MooseX::Types::Email;
use MooseX::Types::Path::Tiny qw/ Path /;
use Try::Tiny;
use PerlX::Maybe;
use List::AllUtils qw/ sum0 /;
use MCE::Map;

use Email::MIME::Kit::Bulk::Kit;
use Email::MIME::Kit::Bulk::Target;


has targets => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Email::MIME::Kit::Bulk::Target]',
    required => 1,
    handles  => {
        targets     => 'elements',
        num_targets => 'count',
    },
);


has kit => (
    is       => 'ro',
    isa      => Path,
    required => 1,
    coerce   => 1,
);


has from => (
    is       => 'ro',
    isa      => 'MooseX::Types::Email::EmailAddress',
    required => 1,
);


has processes => (
    is        => 'ro',
    isa       => 'Maybe[Int]',
    predicate => 'has_processes',
);

sub single_process { 
    no warnings;
    return $_[0]->processes == 1;
}

has verbose => (
    isa => 'Bool',
    is => 'ro',
    default => 0,
);

has transport => (
    is => 'ro',
);

sub mime_kit {
    my $self = shift;
    Email::MIME::Kit::Bulk::Kit->new({
        source => $self->kit->stringify,
        @_,
    });
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $params = $class->$orig(@_);

    if (!exists $params->{targets} && exists $params->{to}) {
        $params->{targets} = [
            Email::MIME::Kit::Bulk::Target->new(
                to => delete $params->{to},
                map { maybe $_ => delete $params->{$_} } qw/ cc bcc /
            )
        ];
    }

    return $params;
};


sub send {
    my $self = shift;

    my $af = STDOUT->autoflush;

    MCE::Map::init { max_workers => $self->processes } 
        if $self->has_processes;

    my $errors = sum0 
        $self->single_process 
            ? map     { $self->send_target($_) } $self->targets
            : mce_map { $self->send_target($_) } $self->targets;

    warn "\n" . ($self->num_targets - $errors) . ' email(s) sent successfully'
       . ($errors ? " ($errors failure(s))" : '') . "\n" if $self->verbose;

    STDOUT->autoflush($af);

    return $self->num_targets - $errors;
}

sub send_target {
    my( $self, $target ) = @_;

    my $email = $self->assemble_mime_kit($target);

    # work around bugs in q-p encoding (it forces \r\n, but the sendmail
    # executable expects \n, or something like that)
    (my $text = $email->as_string) =~ s/\x0d\x0a/\n/g;

    return try {
        sendmail(
            $text,
            {
                from => $target->from,
                to   => [ $target->recipients ],
                maybe transport => $self->transport,
            }
        );
        print '.' if $self->verbose;
        0;
    }
    catch {
        my @recipients = (blessed($_) && $_->isa('Email::Sender::Failure'))
            ? ($_->recipients)
            : ($target->recipients);

        # XXX better error handling here - logging?
        warn 'Failed to send to ' . join(', ', @recipients) . ': '
            . "$_";

        print 'x' if $self->verbose;
        1;
    };
}

sub assemble_mime_kit {
    my $self = shift;
    my ($target) = @_;

    my $from = $target->from || $self->from;
    my $to   = $target->to;
    my @cc   = $target->cc;

    my %opts;
    $opts{language} = $target->language
        if $target->has_language;

    my $kit = $self->mime_kit(%opts);
    my $email = $kit->assemble($target->template_params);

    if (my @attachments = $target->extra_attachments) {
        my $old_email = $email;

        my @parts = map {
            my $attach = ref($_) ? $_ : [$_];
            Email::MIME->create(
                attributes => {
                    filename     => $attach->[0],
                    name         => $attach->[0],
                    encoding     => 'base64',
                    disposition  => 'attachment',
                    ($attach->[1]
                        ? (content_type => $attach->[1])
                        : ()),
                },
                body => ${ $kit->get_kit_entry($attach->[0]) },
            );
        } @attachments;

        $email = Email::MIME->create(
            header => [
                Subject => $old_email->header_obj->header_raw('Subject'),
            ],
            parts => [
                $old_email,
                @parts,
            ],
        );
    }

    # XXX Email::MIME::Kit reads the manifest.json file as latin1
    # fix this in a better way once that is fixed?
    my $subject = $email->header('Subject');
    utf8::decode($subject);
    $email->header_str_set('Subject' => $subject);

    $email->header_str_set('From' => $from)
        unless $email->header('From');
    $email->header_str_set('To' => $to)
        unless $email->header('To');
    $email->header_str_set('Cc' => join(', ', @cc))
        unless $email->header('Cc') || !@cc;

    $email->header_str_set(
        'X-UserAgent' 
            => "Email::MIME::Kit::Bulk v$Email::MIME::Kit::Bulk::VERSION"
    );

    return $email;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Bulk - Email::MIME::Kit-based bulk mailer

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

    use Email::MIME::Kit::Bulk;
    use Email::MIME::Kit::Bulk::Target;

    my @targets = (
        Email::MIME::Kit::Bulk::Target->new(
            to => 'someone@somewhere.com',
        ),
        Email::MIME::Kit::Bulk::Target->new(
            to => 'someone.else@somewhere.com',
            cc => 'copied@somewhere.com',
            language => 'en',
        ),
    );

    my $bulk = Email::MIME::Kit::Bulk->new(
        kit => '/path/to/mime/kit',
        processes => 5,
        targets => \@targets,
    );

    $bulk->send;

=head1 DESCRIPTION

C<Email::MIME::Kit::Bulk> is an extension of L<Email::MIME::Kit> for sending
bulk emails. The module can be used directly, or via the 
companion script C<emk_bulk>.

If a language is specified for a target, C<Email::MIME::Kit> will use
C<manifest.I<language>.json> to generate its associated email. If no language 
is given, the regular C<manifest.json> will be used instead.

If C<emk_bulk> is used, it'll look in the I<kit> directory for a
C<targets.json> file, which it'll use to create the email targets.
The format of the C<targets.json> file is a simple serialization of
the L<Email::MIME::Kit::Bulk::Target> constructor arguments:

    [
    {
        "to" : "someone@somewhere.com"
        "cc" : [
            "someone+cc@somewhere.com"
        ],
        "language" : "en",
        "template_params" : {
            "superlative" : "Fantastic"
        },
    },
    {
        "to" : "someone+french@somewhere.com"
        "cc" : [
            "someone+frenchcc@somewhere.com"
        ],
        "language" : "fr",
        "template_params" : {
            "superlative" : "Extraordinaire"
        },
    }
    ]

C<Email::MIME::Kit::Bulk> uses L<MCE> to parallize the sending of the emails.
The number of processes used can be set via the C<processes> constructor 
argument.  By default L<MCE> will select the number of processes based on
the number of available
processors. If the number of processes is set to be C<1>, L<MCE> is bypassed 
altogether.

=head1 METHODS

=head2 new( %args ) 

Constructor.

=head3 Arguments

=over

=item targets => \@targets

Takes in an array of L<Email::MIME::Kit::Bulk::Target> objects,
which are the email would-be recipients.

Either the argument C<targets> or C<to> must be passed to the constructor.

=item to => $email_address

Email address of the 'C<To:>' recipient. Ignored if C<targets> is given as well.

=item cc => $email_address

Email address of the 'C<Cc:>' recipient. Ignored if C<targets> is given as well.

=item bcc => $email_address

Email address of the 'C<Bcc:>' recipient. Ignored if C<targets> is given as well.

=item kit => $path

Path of the directory holding the files used by L<Email::MIME::Kit>.
Can be a string or a L<Path::Tiny> object.

=item from => $email_address

'C<From>' address for the email .

=item processes => $nbr

Maximal number of parallel processes used to send the emails.

If not specified, will be chosen by L<MCE>.
If set to 1, the parallel processing will be skipped
altogether.

Not specified by default.

=back

=head2 send()

Send the emails.

=head1 AUTHORS

=over 4

=item *

Jesse Luehrs    <doy@cpan.org>

=item *

Yanick Champoux <yanick.champoux@iinteractive.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Infinity Interactive <contact@iinteractive.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
