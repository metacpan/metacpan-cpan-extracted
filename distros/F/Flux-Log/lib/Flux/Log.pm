package Flux::Log;
{
  $Flux::Log::VERSION = '1.00';
}

# ABSTRACT: storage implemented as log.


use Moo;
extends 'Flux::File';
with 'Flux::Storage::Role::ClientList';

use Type::Params qw(validate);
use Types::Standard qw(Str Dict HashRef);

use File::Basename qw(basename);

use Flux::Log::In;
use Flux::Log::Types qw(ClientName);

has '+reopen' => (
    default => sub { 1 },
);

sub description {
    my $self = shift;
    return "log: ".$self->file;
}

has 'client_dir' => (
    is => 'lazy',
    isa => Str,
    default => sub {
        my $self = shift;
        my $dir = $self->file.".pos";
        unless (-d $dir) {
            mkdir $dir or die "mkdir failed: $!";
        }
        return $dir;
    },
);

sub in {
    my $self = shift;
    my ($client_or_params) = validate(\@_, ClientName | Dict[pos => Str]);

    if (ref $client_or_params) {
        return Flux::Log::In->new({
            log => $self->file,
            unrotate => $client_or_params,
        });

    }
    else {
        return Flux::Log::In->new({
            log => $self->file,
            unrotate => {
                pos => $self->client_dir."/".$client_or_params
            }
        });
    }
}

sub client_names {
    my $self = shift;
    my @files = glob $self->client_dir.'/*';
    return map { basename $_ } @files;
}


1;

__END__

=pod

=head1 NAME

Flux::Log - storage implemented as log.

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    my $log = Flux::Log->new("/var/log/my.log");

    $log->write("abc\n");
    $log->commit;

    my $in = $log->in("reader1");
    my $str = $in->read;
    $in->commit;

=head1 DESCRIPTION

C<Flux::Log> is similar to L<Flux::File>, but designed to work with logs (files which can rotate sometimes).

It supports safe writes to rotating logs, i.e. it will automatically switch to the new file instead of writing to C<foo.log.1>.

Note that this module B<doesn't rotate logs by itself>. You have to use L<logrotate(8)> or it's replacement for that.

You don't have to use this module to write logs. If some other program writes a log, you can use C<Flux::Log> to represent such log, and use it to generate input stream objects via C<< $storage->in($client_name) >>.

=head1 NAMED CLIENTS

C<Flux::Log> implements the L<Flux::Storage::Role::ClientList> role. It stores client's position in the I<$log.pos/> dir.

For example, if your log is called I</var/log/my-app.log>, and you attempt to create an input stream by calling C<< $storage->in("abc") >>, I</var/log/my-app.log.pos/> dir will be created (if necessary), and position will be stored in I</var/log/my-app.log.pos/abc>.

=head1 METHODS

=over

=item B<in($client_name)>

=item B<in({ pos => $posfile })>

Construct input stream from a client name or a posfile name.

=back

=head1 SEE ALSO

L<Log::Unrotate> - this module does all the heavy lifting for safe log readings.

L<Flux::File> - simple line-based storage for which this class is a specialization.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
