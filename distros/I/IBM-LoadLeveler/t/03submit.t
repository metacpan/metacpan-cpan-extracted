#########################

use Test::More;
use IBM::LoadLeveler;

# Skip all tests if 02query.t failed, no point running tests if you
# cant get a basic query setup.

if ( -f "SKIP_TEST_LOADLEVELER_NOT_RUNNING" )
{
	plan( skip_all => 'failed basic query, check LoadLeveler running ?');
}
else
{
	plan( tests => 3);
}

#########################


# Job Parameters

my $runtime=300;

# Find a class to submit normal work to

my $query = ll_query(CLASSES);
my $return=ll_set_request($query,QUERY_ALL,undef,ALL_DATA);

SKIP:
{
    skip('ll_set_request to get classes failed',3) if $return != 0;

	my $number=0;
	my $err=0;
   	my $classes=ll_get_objs($query,LL_CM,NULL,$number,$err);
	my $class_name="";
	
	
	while($classes)
	{	
		# Remove any classes that have users specified
		
		my @class_exc_users=ll_get_data($classes,LL_ClassExcludeUsers);
		if ($#class_exc_users > -1)
		{
		    	$classes=ll_next_obj($query);
			next;
		}
	
    		my @class_inc_users=ll_get_data($classes,LL_ClassIncludeUsers);
		if ($#class_inc_users > -1)
		{
		    	$classes=ll_next_obj($query);
			next;
		}
	
    		my @class_exc_group=ll_get_data($classes,LL_ClassExcludeGroups);
		if ($#class_exc_group > -1)
		{
		    	$classes=ll_next_obj($query);
			next;
		}
    
		my @class_inc_group=ll_get_data($classes,LL_ClassIncludeGroups);
		if ($#class_inc_group > -1)
		{
		    	$classes=ll_next_obj($query);
			next;
		}
		
    		$class_name=ll_get_data($classes,LL_ClassName);
		# Avoid anything that looks important
		if (  $class_name =~ /high/     || $class_name =~ /priority/ || $class_name =~ /special/ ||
		      $class_name =~ /parallel/ || $class_name =~ /large/
		   )
		{
		    	$classes=ll_next_obj($query);
			next;
		}
		
		# Check Wall Clock and look for enough time to run our job

	   	my $class_wcl_hlimit=ll_get_data($classes,LL_ClassWallClockLimitHard);
    		my $class_wcl_slimit=ll_get_data($classes,LL_ClassWallClockLimitSoft);
	
		if ( ($class_wcl_hlimit != -1 && $class_wcl_hlimit < ($runtime+60)) || 
		     ($class_wcl_slimit != -1 && $class_wcl_slimit < ($runtime+60)) )
		{
	    		$classes=ll_next_obj($query);
			next;
		}	
		# Anything left that looks ordinary ?
		
		last if (  $class_name =~ /normal/ || $class_name =~ /small/ );
    		$classes=ll_next_obj($query);
	}
	# Free up space allocated by LoadLeveler
	ll_free_objs($query);
	ll_deallocate($query);
	
	ok($class_name ne "","Find a class to run in");
	
	# No point submitting a job if we could not find a class
    skip('Failed to find a job class',2) if $class_name eq "";

	# Free up space allocated by LoadLeveler
	ll_free_objs($query);
	ll_deallocate($query);

	# Make A Command file

	$CmdFile="/tmp/LoadLeveler-test.cmd";

	ok(open(CMD,"> $CmdFile" ),"opening an empty file to generate a JCF");

	print CMD << "EOF";

#!/bin/sh

#@ job_name = perl-loadleveler-test
#@ wall_clock_limit = 1:00
##@ resources = ConsumableCpus(1)
#@ class = $class_name
#@ queue

#
# simulate a compute bound job by killing some time
#

sleep 300

echo The name of this job is $0
echo

echo This job is running on `hostname`
echo

echo This job is running from `pwd`
echo

echo The environment is `env`
echo

echo These ids are logged onto the system:
who


EOF

	close CMD;

	my ($job_name,$owner,$group,$uid,$gid,$host,$steps,$job_step)=llsubmit($CmdFile,NULL,NULL);

	ok(defined $job_name,"llsubmit test job");

	unlink $CmdFile;
}
