package Dist::Setup;

use strict;
use warnings;
use utf8;
use feature ':5.24';
use version 0.77;

use Eval::Safe;
use File::Basename 'basename', 'dirname';
use File::Copy;
use File::Find;
use File::Spec::Functions 'abs2rel', 'catfile';
use Template;
use Time::localtime;

our $VERSION = '0.15';

our %conf;  # to be shared with the Eval::Safe object.
my $tt;
my $tt_raw;
my $target_dir;

my $footer_marker = '# End of the template. You can add custom content below this line.';

sub setup {
  my ($data_dir, $target_dir_local) = @_;
  $target_dir = $target_dir_local;

  my $conf_file_name = 'dist_setup.conf';
  my $conf_file = catfile($target_dir, $conf_file_name);
  if (!-e $conf_file) {
    print STDERR "No ${conf_file_name} in target directory.\n";
    copy(catfile($data_dir, $conf_file_name), $conf_file)
        or die "Cannot copy ${conf_file_name}: $!\n";
    print STDERR "Created a new configuration file. Modify it then run this tool again.\n";
    exit 0;
  }

  my $eval = Eval::Safe->new();
  %conf = %{$eval->do($conf_file)}
      or die "Cannot parse the ${conf_file_name} configuration: $@\n";
  $eval->share('%conf');

  $conf{auto}{date}{year} = localtime->year() + 1900;  ## no critic (ProhibitMagicNumbers)
  $conf{dist_name} //= $conf{name} =~ s/::/-/gr;
  $conf{dist_package} //= $conf{name} =~ s/::/\//gr;  # Undocumented for now, used only by the `make exe` target
  $conf{base_package} //= 'lib/'.($conf{name} =~ s{::}{/}gr).'.pm';
  $conf{footer_marker} = $footer_marker;
  $conf{short_min_perl_version} =
      version->parse($conf{min_perl_version})->normal =~ s/^v(\d+\.\d+)\..*$/$1/r;
  $conf{dotted_min_perl_version} =
      version->parse($conf{min_perl_version})->normal =~ s/^v(\d+(?:\.\d+)*).*$/$1/r;

  if ($conf{github}{use_ci}) {
    $conf{github}{use_ci} = {} unless ref $conf{github}{use_ci};
    $conf{github}{use_ci}{runners} = [qw(ubuntu windows macos)]
        unless exists $conf{github}{use_ci}{runners};
  }

  $tt = Template->new({
    INCLUDE_PATH => $data_dir,
    OUTPUT_PATH => $target_dir,
    ENCODING => 'utf8',
    EVAL_PERL => 1,
    PRE_PROCESS => 'tt_header',
    POST_PROCESS => 'tt_footer',
  });
  $tt_raw = Template->new({
    INCLUDE_PATH => $data_dir,
    OUTPUT_PATH => $target_dir,
    ENCODING => 'utf8',
    EVAL_PERL => 1,
  });

  find({
      no_chdir => 1,
      wanted => sub {
        my $f = basename($_);
        if ($f =~ m/^\./) {
          $File::Find::prune = 1;
          return;
        }
        return if $f eq 'dist_setup.conf';
        return if $f =~ m/^tt_/;
        return if $f =~ m/\.cond$/;

        my $src = abs2rel($_, $data_dir);
        my $out = $src;
        $out =~ s/(^|\/)dot_/${1}./g;

        my $cond_file = -d $_ ? catfile($_, '.cond') : $_.'.cond';
        if (-f $cond_file) {
          my $ret = $eval->do($cond_file);
          die "Cannot evaluate ${cond_file}: $@\n" if $@;
          die "Cannot read ${cond_file}: $!\n" if $!;
          if (!$ret) {
            $File::Find::prune = 1;
            print "Skipped ${out}\n";
            return;
          }
        }
        return if -d $_;
        die "Cannot read $_: $!\n" unless -r $_;

        print "Processing ${out}\n";
        setup_file($src, $out);
      },
    },
    $data_dir);
  return;
}

sub setup_file {
  my ($src_file, $target_file) = @_;
  my $footer = q{};

  my $dest_tt;

  if ($src_file =~ m/\.raw$/) {
    $dest_tt = $tt_raw;
    $target_file =~ s/\.raw$//;
  } else {
    $dest_tt = $tt;
    my $dest_file = catfile($target_dir, $target_file);
    if (-e $dest_file) {
      open my $f, '<:encoding(UTF-8)', $dest_file
          or die "Cannot open '$dest_file': $!\n";
      while (<$f>) {
        last if /^${footer_marker}$/m;
      }
      $footer = do { local $/ = undef; <$f> } unless eof($f);
      $footer =~ s/\n+$//;
      $footer = "\n".$footer if $footer;  # There is no new line before footer in the template.
      close $f or die "Cannot close '$dest_file': $!\n";
    }
  }

  $dest_tt->process($src_file, {%conf, footer_content => $footer},
    $target_file, {binmode => ':utf8'})
      or die "Cannot process template ${src_file}: ".$dest_tt->error()."\n";

  return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Dist::Setup – Internal implementation for the C<perl_dist_setup> tool.

For all the documentation, please refer to the L<perl_dist_setup> page.
