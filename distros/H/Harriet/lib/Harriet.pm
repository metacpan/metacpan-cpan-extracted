package Harriet;
use 5.008005;
use strict;
use warnings;

our $VERSION = "00.05";

sub new {
    my ($class, $dir) = @_;
    bless {dir => $dir}, $class;
}

sub load {
    my ($self, $name) = @_;
    return if $self->{loaded}->{$name}++;

    my $file = "$self->{dir}/${name}.pl";

    my $retval = do $file;
    if ($@) {
        die "[Harriet] Couldn't parse $file: $@\n";
    }
}

sub load_all {
    my ($self) = @_;

    opendir my $dh, $self->{dir}
        or die "[Harriet] Cannot open '$self->{dir}' as directory: $!\n";
    while (my $file = readdir($dh)) {
        next unless $file =~ /^(.*)\.pl$/;
        my $name = $1;
        $self->load($name);
    }
}

1;
__END__

=encoding utf-8

=for stopwords harriet groonga

=head1 NAME

Harriet - Daemon manager for testing

=head1 SYNOPSIS

    use Harriet;

    my $harriet = Harriet->new('t/harriet/');
    $harriet->load('stf');
    print $ENV{TEST_STF}, "\n";

=head1 DESCRIPTION

B<(THIS MODULE IS CURRENTLY UNDER DEVELOPMENT.)>

In some case, test code requires daemons like memcached, STF, or groonga.
If you are running these daemons for each test scripts, it eats lots of time.

Then, you need to keep the processes under the test suite.

Harriet solves this issue.

Harriet loads all daemons when starting L<prove>. And set the daemon's end point to the environment variable.
And run the test cases. Test script can use the daemon process (You need to clear the data if you need.).

=head1 TUTORIAL

=head2 Writing harriet script

harriet script is just a perl script has C<.pl> extension. Example code is here:

    # t/harriet/memcached.pl
    use strict;
    use utf8;

    use Test::TCP;

    $ENV{TEST_MEMCACHED} ||= do {
        my $server = Test::TCP->new(
            code => sub {
                my $port = shift;
                exec '/usr/bin/memcached', '-p', $port;
                die $!;
            }
        );
        $HARRIET_GUARDS::MEMCACHED = $server;
        '127.0.0.1:' . $server->port;
    };

This code runs memcached. It returns memcached's end point information and guard object. Harriet keeps guard objects while perl process lives.

(Guard object is optional.)

=head2 Load harriet script

    use Harriet;

    my $harriet = Harriet->new('t/harriet');
    $harriet->load('memcached');
    print $ENV{memcached}, "\n";

This script load the memcached daemon setup script.
harriet loads harriet script named 't/harriet/memcached.pl'.

=head2 Save daemon process under the prove

    # .proverc
    -PHarriet=t/harriet/

L<App::Prove::Plugin::Harriet> loads harriet scripts under the C<t/harriet/>, and set these to environment variables.

This plugin starts daemons before running test cases!

=head1 WHY Harriet?

L<Harriet|http://en.wikipedia.org/wiki/Harriet_(tortoise)> is very long lived tortoise. Harriet.pm makes long lived process.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

