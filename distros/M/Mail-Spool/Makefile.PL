use ExtUtils::MakeMaker;


my %args = (
            'NAME'	      => 'Mail::Spool',
            'VERSION_FROM'    => 'lib/Mail/Spool.pm',
            
            'PREREQ_PM'	      => {
              'File::NFSLock'  => '1.10',
              'Net::DNS'       => 0,
              'Net::SMTP'      => 0,
              'IO::File'       => 0,
              'Mail::Internet' => 0,
              'Mail::Address'  => 0,
            },
            
            dist              => {
              DIST_DEFAULT => 'all tardist',
              COMPRESS     => 'gzip -vf',
              SUFFIX       => '.gz',
            },
            
            clean             => {
              FILES        => '*~',
            },
            
            realclean         => {
              FILES        => '*~',
            },
            
            );

WriteMakefile(%args);

package MY;

sub libscan {
  my $self = shift;
  my $path = shift;
  ($path =~ / \bCVS\b | \~$ /x) ? undef : $path;
}

sub postamble {
  return qq^
    
pm_to_blib: README

README: lib/Mail/Spool.pm
\tpod2text lib/Mail/Spool.pm >README
  ^;
}

1;
