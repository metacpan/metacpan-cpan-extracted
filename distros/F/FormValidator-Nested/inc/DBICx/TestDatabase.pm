#line 1
package DBICx::TestDatabase;
use strict;
use warnings;

use File::Temp 'tempfile'; 

our $VERSION = '0.02';

# avoid contaminating the schema with the tempfile
my @TMPFILES;

sub new {
    my ($class, $schema_class) = @_;
    
    eval "require $schema_class" 
      or die "failed to require $schema_class: $@";
    
    my (undef, $filename) = tempfile;
    my $schema = $schema_class->connect("DBI:SQLite:$filename") 
      or die "failed to connect to DBI:SQLite:$filename ($schema_class)";

    push @TMPFILES, $filename;
    
    $schema->deploy;
    return $schema;
}

END {
    # for some reason unlink after write doesn't unlink the files on
    # my system

    if($ENV{DBIC_KEEP_TEST}){
        print {*STDERR} "Keeping DBICx::TestDatabase databases: @TMPFILES\n";
    }
    else {
        unlink @TMPFILES;
    }
}

*connect = *new;

1;

__END__

