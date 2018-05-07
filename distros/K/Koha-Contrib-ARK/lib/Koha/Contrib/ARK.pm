package Koha::Contrib::ARK;
$Koha::Contrib::ARK::VERSION = '1.0.0';
# ABSTRACT: ARK Management
use Moose;

extends 'AnyEvent::Processor::Conversion';

use Modern::Perl;
use JSON;
use DateTime;
use Try::Tiny;
use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::File;
use Koha::Contrib::ARK::Updater;
use Koha::Contrib::ARK::Clearer;



has c => ( is => 'rw', isa => 'HashRef' );


has cmd => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my ($self, $cmd) = @_;
        $self->fatal("Invalid command: $cmd\n")
            if $cmd !~ /check|clear|update/;
        return $cmd;
    },
    default => 'check',
);


has doit => ( is => 'rw', isa => 'Bool', default => 0 );

has verbose => ( is => 'rw', isa => 'Bool', default => 0 );

has loglevel => (
    is => 'rw',
    isa => 'Str',
    default => 'debug',
);

has field_query => ( is => 'rw', isa => 'Str' );

has log => (
    is => 'rw',
    isa => 'Log::Dispatch',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $log = Log::Dispatch->new();
        $log->add( Log::Dispatch::File->new(
            name      => 'file1',
            min_level => $self->loglevel,
            filename  => './koha-ark.log',
            mode      => '>>',
            binmode   => ':encoding(UTF-8)',
        ) );
        return $log;
    }
);


sub fatal {
    my ($self, $msg) = @_;
    $self->log->error( "$msg\n" );
    exit;
}


sub BUILD {
    my $self = shift;

    my $dt = DateTime->now();
    $self->log->info("\n" . ('-' x 80) . "\nkoha-ark: start -- " . $dt->ymd . " " . $dt->hms . "\n");
    $self->log->info("** TEST MODE **\n") unless $self->doit;
    $self->log->debug("Reading ARK_CONF\n");
    my $c = C4::Context->preference("ARK_CONF");
    $self->fatal("ARK_CONF Koha system preference is missing") unless $c;
    $self->log->debug("ARK_CONF=\n$c\n");

    try {
        $c = decode_json($c);
    } catch {
        $self->fatal("Error while decoding json ARK_CONF preference: $_");
    };

    my $a = $c->{ark};
    $self->fatal("Invalid ARK_CONF preference: 'ark' variable is missing") unless $a;

    # Check koha fields
    for my $name ( qw/ id ark / ) {
        my $field = $a->{koha}->{$name};
        $self->fatal("Missing: koha.$name") unless $field;
        $self->fatal("koha.$name is not a hash") if ref $field ne "HASH";
        $self->fatal("Missing: koha.$name.tag") unless $field->{tag};
        $self->fatal("Invalid koha.$name.tag") if $field->{tag} !~ /^[0-9]{3}$/;
        $self->fatal("Missing koha.$name.letter")
            if $field->{tag} !~ /^00[0-9]$/ && ! $field->{letter};
    }

    my $id = $a->{koha}->{ark};
    my $field_query =
        $id->{letter}
        ? '//datafield[@tag="' . $id->{tag} . '"]/subfield[@code="' .
          $id->{letter} . '"]'
        : '//controlfield[@tag="' . $id->{tag} . '"]';
    $field_query = "ExtractValue(metadata, '$field_query')";
    $self->log->debug("field_query = $field_query\n");
    $self->field_query( $field_query );

    $self->c($c);

    # Instanciation reader/writer/converter
    $self->reader( Koha::Contrib::ARK::Reader->new(
        ark => $self,
        emptyark => $self->cmd eq 'update',
    ) );
    $self->writer( Koha::Contrib::ARK::Writer->new( ark => $self ) );
    $self->converter( $self->cmd eq 'update'
        ? Koha::Contrib::ARK::Updater->new( ark => $self )
        : Koha::Contrib::ARK::Clearer->new( ark => $self )
    );
}


sub build_ark {
    my ($self, $biblionumber, $record) = @_;

    my $a = $self->c->{ark};
    my $ark = $a->{ARK};
    for my $var ( qw/ NMHA NAAN / ) {
        my $value = $a->{$var};
        $ark =~ s/{$var}/$value/;
    }
    my $kfield = $a->{koha}->{id};
    my $id = $record->field($kfield->{tag});
    if ( $id ) {
        $id = $kfield->{letter}
            ? $id->subfield($kfield->{letter})
            : $id->value;
    }
    unless ($id) {
        $self->log->warning("No koha.id field. Use biblionumber instead\n");
        $id = $biblionumber;
    }
    $ark =~ s/{id}/$id/;
    return $ark;
}


override 'start_message' => sub {
    my $self = shift;
    say "ARK processing: ", $self->cmd;
};


override 'end_message' => sub {
    my $self = shift;
    say "Number of biblio records processed: ", $self->count;
};


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK - ARK Management

=head1 VERSION

version 1.0.0

=head1 ATTRIBUTES

=head2 cmd

What processing? One of those values: check, clear, update. By default,
'check'.

=head2 doit

Is the process effective?

=head2 verbose

Operate in verbose mode

=head2 loglevel

Logging level. The usual suspects: debug info warn error fatal.

=head1 METHODS

=head2 build_ark($biblionumber, $record)

Build ARK for biblio record $record (which has $biblionumber unique ID)

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
