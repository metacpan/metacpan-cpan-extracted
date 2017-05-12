use Cwd;


my @args = ("clamd", "-V");

#can we run clamd?
if(! system(@args) == 0){
    warn "Can't execute clamd, trying again with CLAMD_PATH environment path...\n";
    #try again with custom path
    @args = ("$ENV{CLAMD_PATH}clamd", "-V");
    if(! system(@args) == 0){
        die "Failed to execute: `@args`. Are your paths set up? Are you root?\n";
    }
    warn "Success: `@args`\n";

}

open(CONF, ">clamav.conf") || die "Cannot write: $!";

my $dir = cwd;

print CONF <<"EOCONF";
LocalSocket $dir/clamsock
Foreground true
MaxThreads 1
ScanArchive true
  
EOCONF

close CONF;
