use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @ppd;
if ($] >= 5.00503) {
  @ppd = (
    AUTHOR    => 'Henrique Dias <hdias@esb.ucp.pt>',
    ABSTRACT  => 'Module for change passwords via poppassd daemon'
  );
}

WriteMakefile(
    'NAME'	=> "Mail::PopPwd",
    'DISTNAME'	=> "Mail-PopPwd",
    'VERSION_FROM' => "PopPwd.pm", # finds $VERSION
    'PREREQ_PM'	=> {
		Crypt::Cracklib => 0.01, # Module::Name => 1.1
		},
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
    @ppd
);
