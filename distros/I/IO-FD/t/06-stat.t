use Test::More skip_all=>"IO::FD::stat is currently broken";
use IO::FD;
use File::Basename qw<dirname basename>;


my @labels=qw<dev      
             ino      
             mode     
             nlink    
             uid      
             gid      
             rdev     
             size     
             atime    
             mtime    
             ctime    
             blksize  
             blocks   
>;

#Create a symlink
my $dir=dirname __FILE__;
my $basename=basename __FILE__;

my $link= "$dir/new";
unlink $link;
ok symlink($basename, $link), "Create symlink";

#LIST CONTEXT
{
	#STAT a file name. LIST CONTEXT
	my @perl=stat __FILE__;
	my @iofd=IO::FD::stat __FILE__;
	for(0..$#labels){
		ok $perl[$_] eq $iofd[$_], $labels[$_];
	}
}
{
	#STAT a filehandle or descriptor. LIST CONTEXT
	my @perl=stat STDIN;
	my @iofd=IO::FD::stat fileno STDIN;
	for(0..$#labels){
		ok $perl[$_] eq $iofd[$_], $labels[$_];
	}
}
{
	#Stat a symbolic link
	my @perl=stat $link;
	my @iofd=IO::FD::stat $link;
	for(0..$#labels){
		ok $perl[$_] eq $iofd[$_], $labels[$_];
	}

	@perl=lstat $link;
	@iofd=IO::FD::lstat $link;
	for(0..$#labels){
		ok $perl[$_] eq $iofd[$_], $labels[$_];
	}




}

#SCALAR CONTEXT
{
        #STAT a file name.
        my $perl=stat __FILE__;
        my $iofd=IO::FD::stat __FILE__;
        ok $perl and $iofd, "Scalar path";
}
{
        #STAT a filehandle or descriptor
        my $perl=stat STDIN;
        my $iofd=IO::FD::stat fileno STDIN;
        ok $perl and $iofd, "Scalar fh";
}

{
        #Stat a symbolic link

        my $perl=stat $link;
        my $iofd=IO::FD::stat $link;
        ok !$perl == !$iofd, "Scalar symlink";

        my $perl=lstat $link;
        my $iofd=IO::FD::lstat $link;
        ok !$perl == !$iofd, "Scalar symlink";

}
done_testing;



