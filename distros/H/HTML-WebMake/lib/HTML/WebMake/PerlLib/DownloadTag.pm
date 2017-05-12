#perl

package HTML::WebMake::PerlLib::DownloadTag;

use POSIX qw(strftime);
use File::Spec;
use File::Basename;

sub handle_download_tag {
  my ($tagname, $attrs, $text, $self) = @_;
  my $file = $attrs->{file};

  $text = $attrs->{text};
  $text ||= '${download.template}';
  
  my $origfile = $self->{main}->fileless_subst ('<download>', $file);
  my ($realfname, $relfname) =
  		$self->{main}->expand_relative_filename ($origfile);

  if (!defined $realfname) {
    warn "<download>: cannot find file \"$origfile\"\n";
    $file = $origfile;
    $self->set_content ('download.path', $origfile);
    $self->set_content ('download.href', $origfile);
  } else {
    $file = $realfname;
    $self->set_content ('download.path', $realfname);
    $self->set_content ('download.href', $relfname);
  }
  $self->set_content ('download.name', basename ($file));

  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
     $atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
  if (!defined $size) {
    warn "<download>: cannot find file \"$file\"\n";
    $mode = $uid = $gid = $size = $atime = $mtime = $ctime = 0;
  }

  $self->set_content ('download.size', $size);
  $self->set_content ('download.size_in_k', int (($size+1023) / 1024));
  $self->set_content ('download.mtime', $mtime);

  {
    my $time = strftime ("%a %b %e %H:%M:%S %Y",
	      localtime ($mtime));
    $self->set_content ('download.mdate', $time);
  }

  {
    my $name = getpwuid($uid);
    $self->set_content ('download.owner', $name);
  }

  {
    my $grp = getgrgid($gid);
    $self->set_content ('download.group', $grp);
  }

  {
    my $attstr = '';
    delete $attrs->{file};
    delete $attrs->{text};
    foreach my $key (keys %{$attrs}) {
      $attstr .= $key.'="'.$attrs->{$key}.'" ';
    }
    chop $attstr;
    $self->set_content ('download.tag_attrs', $attstr);
  }

  return $self->{main}->fileless_subst ('<download>', $text);
}

1;
