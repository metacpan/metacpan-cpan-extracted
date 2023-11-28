package SequenceFileReader;
#
# Translated from
# http://stackoverflow.com/questions/10798060/convert-sequence-file-and-get-key-value-pairs-via-map-and-reduce-tasks-in-hadoo
#
use 5.014;
use strict;
use warnings;

use constant {
    GIVE_UP_LIMIT => 4,
    SAMPLE_LEN    => 200,
};

use Moo;
use Data::Dumper;

use Hadoop::Inline::ClassLoader
    {
        extra_classpath => [ qw( /usr/lib/hadoop/client/* ) ],
        alias           => 1,
    },
    qw(
        org.apache.hadoop.conf.Configuration
        org.apache.hadoop.fs.FileSystem
        org.apache.hadoop.fs.Path
        org.apache.hadoop.io.IntWritable
        org.apache.hadoop.io.SequenceFile
        org.apache.hadoop.io.SequenceFile$Reader
        org.apache.hadoop.io.Text
        org.apache.hadoop.io.IOUtils
        org.apache.hadoop.io.Writable
        org.apache.hadoop.util.ReflectionUtils

        org.slf4j.Logger
        org.slf4j.LoggerFactory
        java.io.IOException
        java.net.URI
);

use Inline::Java qw(
    cast
);

my $LOG = cast 'org.slf4j.Logger'
                    => org::slf4j::LoggerFactory->getLogger( __PACKAGE__ );

$LOG->info( 'Now we can use the native logger too' );

sub read_file {
    my $self = shift;
    my $uri  = shift;

    $LOG->info( 'Starting the reader' );

    # aliased from org::apache::* (which is also available)
    #
    my $conf   = Hadoop::Conf::Configuration->new;
    my $fs     = Hadoop::Fs::FileSystem->get(
                        java::net::URI->create( $uri ),
                        $conf,
                    );
    my $path   = Hadoop::Fs::Path->new( $uri );

    my $reader = Hadoop::Io::SequenceFile::Reader->new(
                        $fs,
                        $path,
                        $conf,
                    );

    my $key    = Hadoop::Util::ReflectionUtils->newInstance(
                        $reader->getKeyClass,
                        $conf,
                    );
    my $value  = Hadoop::Util::ReflectionUtils->newInstance(
                        $reader->getValueClass,
                        $conf,
                    );

    my $position = $reader->getPosition;

    my $tot;
    while ( my @f = $reader->next($key, $value) ) {
        my $syncSeen = $reader->syncSeen ? q{*} : q{};
        printf("[%s%s]\t%s\t%s\n", $position, $syncSeen, $key, $value);
        $position = $reader->getPosition;

        say substr $value->toString, 0, SAMPLE_LEN;

        say 'Enough!', last if $tot++ > GIVE_UP_LIMIT;
    }

    Hadoop::Io::IOUtils->closeStream( $reader );

    $LOG->info( 'FIN.' );

    return;
}

1;

__END__
