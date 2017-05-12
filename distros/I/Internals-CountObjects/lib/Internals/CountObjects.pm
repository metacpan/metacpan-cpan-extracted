package Internals::CountObjects;
BEGIN {
  $Internals::CountObjects::VERSION = '0.05';
}
# ABSTRACT: Report all allocated perl objects

use strict;
use vars qw( @ISA @EXPORT_OK %EXPORT_TAGS );

require XSLoader;
XSLoader::load( __PACKAGE__, $Internals::CountObjects::VERSION );

use Exporter;
@ISA = 'Exporter';
@EXPORT_OK = qw(
    objects
    dump_objects
);
%EXPORT_TAGS = (
    all => \ @EXPORT_OK,
);

# Provided by CountObjects.xs
sub objects;

sub dump_objects {
    local $@;
    return
        $_[0]
            ? _dump_objects_delta( $_[0] )
            : _dump_objects();
}

sub _dump_objects {
    my $objects = objects();
    return
        join '',
            "Memory stats\n",
            map { "=$$= $_: $objects->{$_}\n" }
            sort { $objects->{$b} <=> $objects->{$a} }
            keys %$objects;
}

sub _dump_objects_delta {
    my $prev_objects = $_[0];
    my $objects = objects();

    my %delta;
    @delta{
        keys( %$objects ),
        keys( %$prev_objects ),
    } = ();

    for ( keys %delta ) {
        my $prev = $prev_objects->{$_} || 0;
        my $now  = $objects     ->{$_} || 0;
        $delta{$_} = $now - $prev;
    }

    return
        join '',
            "Memory stats (delta from previous)\n",
            map {
                my $prev = $prev_objects->{$_};
                my $now  = $objects     ->{$_} || 0;
                my $d = $delta{$_};
                if ($d > 0) {
                    $d = "+$d";
                }

                $d
                    ? "=$$= $_: $now ($d)\n"
                    : "=$$= $_: $now\n";
            }
            sort { $delta{$b} <=> $delta{$a} }
            keys %delta;
}

'Insisting on maintaining dignity at all costs is paralyzing. Mistakes are informative, and so is playing the fool'

__END__

=head1 NAME

Internals::CountObjects - Report all allocated perl objects

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Internals::CountObjects;
  print dump_objects();

=head1 DESCRIPTION

This module provides a simple count of each kind of object in
memory. It can be used as an ordinary perl module or injected into
running processes in production emergencies.

An example report, including the process ID on each line:

  =7201= Memory stats
  =7201= undef: 1176
  =7201= REF: 781
  =7201= ARRAY: 484
  =7201= GLOB: 388
  =7201= string/integer: 262
  =7201= integer: 253
  =7201= CODE: 162
  =7201= string/double: 139
  =7201= HASH: 87
  =7201= REGEXP: 60
  =7201= IO::File: 8
  =7201= version: 3
  =7201= double: 3
  =7201= FORMAT: 2
  =7201= string: 1
  =7201= Config: 1

=head1 FUNCTIONS

=head2 dump_objects()

Returns a formatted report.

=head2 dump_objects($prev_objects)

Returns a formatted report, showing the differences between a previous call to C<objects()>.

  $objects = objects();
  # do something
  print dump_objects($objects);

  Memory stats (delta from previous)
  =2628= integer: 272 (+11)
  =2628= REF: 798 (+4)
  =2628= string/integer: 272 (+2)
  =2628= string: 2 (+1)
  =2628= ARRAY: 493 (+1)
  =2628= double: 4 (+1)
  =2628= HASH: 90 (+1)
  =2628= FORMAT: 2
  =2628= IO::File: 8
  =2628= version: 3
  =2628= CODE: 164
  =2628= Config: 1
  =2628= REGEXP: 60
  =2628= GLOB: 394
  =2628= string/double: 139
  =2628= undef: 1362 (-21)

=head2 objects()

Returns the data used for the report in a hash reference. An example
of a typical hash:

  %report = (
    'undef'          => 1176,
    'REF'            => 781,
    'ARRAY'          => 484,
    'GLOB'           => 388,
    'string/integer' => 262,
    'integer'        => 253,
    'CODE'           => 162,
    'string/double'  => 139,
    'HASH'           => 87,
    'REGEXP'         => 60,
    'IO::File'       => 8,
    'version'        => 3,
    'double'         => 3,
    'FORMAT'         => 2,
    'string'         => 1,
    'Config'         => 1
  );

=head1 IN EMERGENCIES

You can get this kind of report from a running perl / httpd
process. You attach to the process with gdb and eval() some ordinary
perl code.

In the below example, we'll pick a httpd, attach to it and eval some
perl to get a report. It's a good idea to kill the process off
afterward.

  $ ps ax | grep httpd
  11340 pts/1    t      0:00 grep httpd
  11342 ?        Ss     0:12 /usr/bin/httpd -f /var/www/conf/httpd.conf
  11343 ?        S      0:03 /usr/bin/httpd -f /var/www/conf/httpd.conf
  11344 ?        S      0:00 /usr/bin/httpd -f /var/www/conf/httpd.conf
  11346 ?        R      0:00 /usr/bin/httpd -f /var/www/conf/httpd.conf

  $ gdb -p 11346
  (gdb) call Perl_eval_pv("use Internals::CountObjects; print STDERR dump_objects()", 0)
  (gdb) detach
  (gdb) quit