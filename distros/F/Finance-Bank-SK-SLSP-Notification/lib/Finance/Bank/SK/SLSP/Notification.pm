package Finance::Bank::SK::SLSP::Notification;

use warnings;
use strict;

our $VERSION = '0.02';

use Email::MIME;
use File::Temp qw(tempdir);
use Path::Class qw(file dir);
use Archive::Extract;
use File::Find::Rule;
use Encode 'from_to';
use Email::Address;

use Finance::Bank::SK::SLSP::Notification::Transaction;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw{
    header_obj
    attached_files
    transactions
    _tmpdir
});

sub new {
    my ($class, %params) = @_;

    $params{attached_files} ||= [];
    $params{transactions} ||= [];
    my $self  = $class->SUPER::new({ %params });

    return $self;
}

sub email_name {
    my ($self) = @_;
    my ($from) = Email::Address->parse($self->header_obj->header('From'));
    return $from->name;
}

sub email_from {
    my ($self) = @_;
    my ($from) = Email::Address->parse($self->header_obj->header('From'));
    return $from->address;
}

sub from_email {
    my ($class, $email) = @_;

    my $parsed = Email::MIME->new($email);
    foreach my $part ($parsed->parts) {

        my $filename = $part->filename;
        next unless $filename;
        next unless $filename =~ m/\.zip$/;
        my $body = $part->body;

        my $tmpdir = tempdir( CLEANUP => 1 );
        my $zip_file = file($tmpdir, $filename);
        $zip_file->spew($body);
        my $extract_dir = dir($tmpdir, 'extracted');
        $extract_dir->mkpath;

        my $ae = Archive::Extract->new( archive => $zip_file ) || die 'fail '.$!;
        $ae->extract( to => $extract_dir ) || die $ae->error;

        my @transactions;
        my @files =
            map { file($_) }
            File::Find::Rule
            ->file()
            ->name( '*' )
            ->in( $extract_dir );
        foreach my $file (@files) {
            next unless $file->basename =~ m/\.txt$/;
            my $content = $file->slurp;
            from_to($content,"windows-1250","utf-8");
            $file->spew($content);

            # process transactions
            if ($file->basename =~ m/^K\d+\.txt$/) {
                push(@transactions, Finance::Bank::SK::SLSP::Notification::Transaction->from_txt($content));
            }
        }

        return $class->new(
            header_obj          => $parsed->header_obj,
            attached_files      => \@files,
            transactions        => \@transactions,
            _tmpdir             => $tmpdir,
        )
    }
}

sub has_transactions {
    my ($self) = @_;
    return @{$self->transactions || []};
}

1;


__END__

=head1 NAME

Finance::Bank::SK::SLSP::Notification - parse email notifications

=head1 SYNOPSIS

    my $slsp = Finance::Bank::SK::SLSP::Notification->from_email($email_str);

    say $slsp->header_obj->header('From');
    say $slsp->attached_files;
    say $slsp->has_transactions;

    say $slsp->transactions->[0]->type;
    say $slsp->transactions->[0]->account_number;
    say $slsp->transactions->[0]->vs;
    say $slsp->transactions->[0]->ks;
    say $slsp->transactions->[0]->ss;

=head1 DESCRIPTION

=head1 PROPERTIES

=head1 METHODS

=head2 new()

Object constructor.

=head1 AUTHOR

Jozef Kutej

=cut
