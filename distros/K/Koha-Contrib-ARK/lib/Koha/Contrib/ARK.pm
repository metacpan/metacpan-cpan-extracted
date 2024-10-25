package Koha::Contrib::ARK;
# ABSTRACT: ARK Management
$Koha::Contrib::ARK::VERSION = '1.1.2';
use Moose;
use Modern::Perl;
use JSON;
use DateTime;
use Try::Tiny;
use Koha::Contrib::ARK::Reader;
use Koha::Contrib::ARK::Writer;
use Koha::Contrib::ARK::Update;
use Koha::Contrib::ARK::Clear;
use Koha::Contrib::ARK::Check;
use Koha::Contrib::ARK::Fix;
use Term::ProgressBar;
use C4::Context;


# Action/error id/message
my $raw_actions = <<EOS;
found_right_field      ARK found in the right field
found_wrong_field      ARK found in the wrong field
found_bad_ark          Bad ARK found in ARK field
not_found              ARK not found
build                  ARK Build
clear                  Clear ARK field
add                    Add ARK field
fix                    Fix bad ARK found in correct ARK field
remove_existing        Remove existing field while adding ARK field
generated              ARK generated
use_biblionumber       No koha.id field, use biblionumber to generate ARK
err_pref_missing       ARK_CONF preference is missing
err_pref_decoding      Can't decode ARK_CONF
err_pref_ark_missing   Invalid ARK_CONF preference: 'ark' variable is missing
err_pref_var_missing   A variable is missing
err_pref_nothash       Variable is not a HASH
err_pref_var_tag       Tag invalid
err_pref_var_letter    Letter missing
EOS

my $what = { map {
    /^(\w*) *(.*)$/;
    { $1 => { id => $1, msg => $2 } }
} split /\n/, $raw_actions };


has c => ( is => 'rw', isa => 'HashRef' );


has cmd => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my ($self, $cmd) = @_;
        $self->error("Invalid command: $cmd\n")
            if $cmd !~ /check|clear|update|fix/;
        return $cmd;
    },
    default => 'check',
);


has fromwhere => ( is => 'rw', isa => 'Str' );

has doit => ( is => 'rw', isa => 'Bool', default => 0 );


has verbose => ( is => 'rw', isa => 'Bool', default => 0 );


has debug => ( is => 'rw', isa => 'Bool', default => 0 );


has field_query => ( is => 'rw', isa => 'Str' );

has reader => (is => 'rw', isa => 'Koha::Contrib::ARK::Reader' );
has writer => (is => 'rw', isa => 'Koha::Contrib::ARK::Writer' );
has action => (is => 'rw', isa => 'Koha::Contrib::ARK::Action' );


has explain => (
    is => 'rw',
    isa => 'HashRef',
);


has current => (
    is => 'rw',
    isa => 'HashRef',
);


sub set_current {
    my ($self, $biblio) = @_;

    my $current = {
        biblio => $biblio,
        modified => 0,
    };
    $self->current($current);

    return unless $biblio;


    my $record = MARC::Moose::Record::new_from($biblio->metadata->record(), 'Legacy');
    return unless $record;

    $biblio->{record} = $record;
    $current->{biblionumber} = $biblio->biblionumber;
    $current->{before} = tojson($record) if $self->debug;
    $current->{ark} = $self->build_ark($biblio->biblionumber, $record);
    
    #$self->what_append('generated', $ark);
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
        $id =~ s/^ *//; $id =~ s/ *$//; # trim left/right
    }
    unless ($id) {
        $self->what_append('use_biblionumber');
        $id = $biblionumber;
    }
    $ark =~ s/{id}/$id/;

    return $ark;
}


sub current_modified {
    my $self = shift;
    $self->current->{modified} = 1;
}


sub error {
    my ($self, $id, $more) = @_;
    my %r = %{$what->{$id}};
    $r{more} = $more if $more;
    $self->explain->{error}->{$id} = \%r;
}


sub what_append {
    my ($self, $id, $more) = @_;
    my %r = %{$what->{$id}};
    $r{more} = $more if $more;
    $self->current->{what}->{$id} = \%r;
}


sub dump_explain {
    my $self = shift;

    open my $fh, '>:encoding(utf8)', 'koha-ark.json';
    print $fh to_json($self->explain, { pretty => 1 });
}


sub BUILD {
    my $self = shift;

    my $tz = DateTime::TimeZone->new( name => 'local' );
    my $dt = DateTime->now( time_zone => $tz );;
    my $explain = {
        action => $self->cmd,
        timestamp => '"' . $dt->ymd . " " . $dt->hms . '"',
        testmode => $self->doit ? 0 : 1,
    };
    $self->explain($explain);

    my $c = C4::Context->preference("ARK_CONF");
    unless ($c) {
        $self->error('err_pref_missing');
        return;
    }

    try {
        $c = decode_json($c);
    } catch {
        $self->error('err_pref_decoding', $_);
        return;
    };

    my $a = $c->{ark};
    unless ($a) {
        $self->error('err_pref_ark_missing');
        return;
    }

    # Check koha fields
    for my $name ( qw/ id ark / ) {
        my $field = $a->{koha}->{$name};
        unless ($field) {
            $self->error('err_pref_var_missing', "koha.$name");
            next;
        }
        if ( ref $field ne "HASH" ) {
            $self->error('err_pref_nothash', "koha.$name");
            next;
        }
        if ( $field->{tag} ) {
            $self->error('err_pref_var_tag', "koha.$name.tag") if $field->{tag} !~ /^[0-9]{3}$/;
        }
        else {
            $self->error('err_pref_var_missing', "koha.$name.tag");
        }
        $self->error('err_pref_var_letter', "koha.$name.letter")
            if $field->{tag} !~ /^00[0-9]$/ && ! $field->{letter};
    }
    $self->explain->{ark_conf} = $c;

    my $id = $a->{koha}->{ark};
    my $field_query =
        $id->{letter}
        ? '//datafield[@tag="' . $id->{tag} . '"]/subfield[@code="' .
          $id->{letter} . '"]'
        : '//controlfield[@tag="' . $id->{tag} . '"]';
    $field_query = "ExtractValue(metadata, '$field_query')";
    $self->field_query( $field_query );

    $self->c($c);

    # Instanciation reader/writer/converter
    $self->reader( Koha::Contrib::ARK::Reader->new(
        ark         => $self,
        fromwhere  => $self->fromwhere,
        select     => $self->cmd eq 'update' ? 'WithoutArk' :
                      $self->cmd eq 'clear'  ? 'WithArk' : 'All',
    ) );
    $explain->{result} = {
        count => $self->reader->total,
        records => [],
    };
    $self->explain($explain);
    $self->writer( Koha::Contrib::ARK::Writer->new( ark => $self ) );
    $self->action(
        $self->cmd eq 'check'  ? Koha::Contrib::ARK::Check->new( ark => $self ) :
        $self->cmd eq 'fix'    ? Koha::Contrib::ARK::Fix->new( ark => $self ) :
        $self->cmd eq 'update' ? Koha::Contrib::ARK::Update->new( ark => $self ) :
                                 Koha::Contrib::ARK::Clear->new( ark => $self )
    );
}


sub tojson {
    my $record = shift;
    my $rec = {
        leader => $record->leader,
        fields => [ map {
            my @values = ( $_->tag );
            if ( ref($_) eq 'MARC::Moose::Field::Control' ) {
                push @values, $_->value;
            }
            else {
                push @values, $_->ind1 . $_->ind2;
                for (@{$_->subf}) {
                    push @values, $_->[0], $_->[1];
                }
            }
            \@values;
        } @{ $record->fields } ],
    };
    return $rec;
}


sub run {
    my $self = shift;

    unless ( $self->explain->{error} ) { 
        my $progress;
        $progress = Term::ProgressBar->new({ count => $self->reader->total })
            if $self->verbose;
        my $next_update = 0;
        while ( $self->reader->read() ) {
            my $current = $self->current;
            if ( $current->{biblionumber} ) {
                $self->action->action();
                my $modified = $current->{modified};
                $current->{after} = Koha::Contrib::ARK::tojson($current->{biblio}->{record})
                    if $self->debug && $modified;
                $self->writer->write()
                    if $self->cmd ne 'check' && $modified;
                if ($self->cmd eq 'check' || $self->current->{modified}) {
                    delete $current->{$_} for qw/ biblio /;
                    push @{$self->explain->{result}->{records}}, $current;
                }
            }
            my $count = $self->reader->count;
            next unless $progress;
            $next_update = $progress->update($count) if $count >= $next_update;
            last if $self->reader->count == 1000000;
        }
    }
    $self->dump_explain();
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK - ARK Management

=head1 VERSION

version 1.1.2

=head1 ATTRIBUTES

=head2 cmd

What processing? One of those values: check, clear, update. By default,
'check'.

=head2 fromwhere

WHERE clause to select biblio records in biblio_metadata table

=head2 doit

Is the process effective?

=head2 verbose

Operate in verbose mode

=head2 debug

In debug mode, there is more info produces. By default, false.

=head2 explain

A HASH containing the full explanation of the pending processing

=head2 current

What happens on the current biblio record?

=head1 METHODS

=head2 set_current($biblio)

Set the current biblio record. Called by the biblio records reader.

=head2 error($id, $more)

Set an error code $id to the L<explain> processing status. $more can contain
more information.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
