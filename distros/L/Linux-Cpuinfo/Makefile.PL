use ExtUtils::MakeMaker;

if ( ! -f '/proc/cpuinfo' )
{
   print <<EONOCPUINFO;
****************************************************

You dont appear to have /proc/cpuinfo on your system 
If you have a similar file located elsewhere then this
module may well still work - if you dont however then
its unlikely this module will be very useful to you.

****************************************************
EONOCPUINFO
}

WriteMakefile(
    'NAME'		=> 'Linux::Cpuinfo',
    'VERSION_FROM'	=> 'lib/Linux/Cpuinfo.pm', 
    'PREREQ_PM'		=> {Test::Simple => 0.47 }, 
    'LICENSE'       => 'perl',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jonathanstowe/Linux-Cpuinfo.git',
                web  => 'https://github.com/jonathanstowe/Linux-Cpuinfo',
            },
        },
    },

    ($] >= 5.005 ?   
      (ABSTRACT_FROM => 'lib/Linux/Cpuinfo.pm',
       AUTHOR     => 'Jonathan Stowe <jns@gellyfish.co.uk>') : ()),
);
