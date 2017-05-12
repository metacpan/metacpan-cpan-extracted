package File::Find::Declare;
our $VERSION = '0.62';

# ABSTRACT: File::Find, declaratively

use strict; #shut up cpants
use warnings; #shut up cpants
use Moose;
use Moose::Util::TypeConstraints;
use Moose::Meta::TypeConstraint;
use MooseX::StrictConstructor;
use File::Util;
use Text::Glob 'glob_to_regex';
use Number::Compare;
use Number::Compare::Date;

#file size subtype with Number::Compare semantics
subtype 'Size'
    => as 'Str'
    => where { $_ =~ m/^(>=|>|<=|<){0,1}\d+(k|ki|m|mi|g|gi){0,1}$/i };

#date subtype with Number::Compare::Date semantics
subtype 'Date'
    => as 'Str';

#available test directives    
enum 'Directive' => qw(readable r_readable writable r_writable
                        executable r_executable owned r_owned
                        exists file empty directory
                        nonempty symlink fifo setuid
                        socket setgid block sticky
                        character tty modified accessed
                        ascii changed binary);

#file permissions subtype                        
subtype 'Perms'
    => as 'Str'
    => where { $_ =~ m/^([r-][w-][x-]){3}$/ };

#file bitmask subtype    
subtype 'Bitmask'
    => as 'Str'
    => where { $_ =~ m/^[1-7]{3}$/ };

#what the file names should look like
has 'like' => (
    is => 'rw',
    isa => 'Str|RegexpRef|ArrayRef[Str|RegexpRef]|Undef',
    predicate => 'has_like',
    reader => '_get_like',
    writer => '_set_like',
);

#what they shouldn't look like
has 'unlike' => (
    is => 'rw',
    isa => 'Str|RegexpRef|ArrayRef[Str|RegexpRef]|Undef',
    predicate => 'has_unlike',
    reader => '_get_unlike',
    writer => '_set_unlike',
);

#acceptable file extensions
has 'ext' => (
    is => 'rw',
    isa => 'Str|ArrayRef[Str]',
    predicate => 'has_ext',
    reader => '_get_ext',
    writer => '_set_ext',
);

#subs that should take one argument and return
#true or false if the file is 'good' or 'bad'
has 'subs' => (
    is => 'rw',
    isa => 'CodeRef|ArrayRef[CodeRef]',
    predicate => 'has_subs',
    reader => '_get_subs',
    writer => '_set_subs',
);

#directories to look in
has 'dirs' => (
    is => 'rw',
    isa => 'Str|ArrayRef[Str]',
    predicate => 'has_dirs',
    reader => '_get_dirs',
    writer => '_set_dirs',
);

#acceptable file sizes, using Number::Compare semantics
has 'size' => (
    is => 'rw',
    isa => 'Size|ArrayRef[Size]',
    predicate => 'has_size',
    reader => '_get_size',
    writer => '_set_size',
);

#created date/time using Number::Compare::Date
has 'changed' => (
    is => 'rw',
    isa => 'Date|ArrayRef[Date]',
    predicate => 'has_changed',
    reader => '_get_changed',
    writer => '_set_changed',
);

#modified date/time using Number::Compare::Date/Number::Compare::Duration
has 'modified' => (
    is => 'rw',
    isa => 'Date|ArrayRef[Date]',
    predicate => 'has_modified',
    reader => '_get_modified',
    writer => '_set_modified',
);

#accessed date/time using Number::Compare::Date/Number::Compare::Duration
has 'accessed' => (
    is => 'rw',
    isa => 'Date|ArrayRef[Date]',
    predicate => 'has_accessed',
    reader => '_get_accessed',
    writer => '_set_accessed',
);

#recursively process subdirectories?
has 'recurse' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
    reader => '_get_recurse',
    writer => '_set_recurse',
);

#filetest directives the file should be like
has 'is' => (
    is => 'rw',
    isa => 'Directive|ArrayRef[Directive]',
    predicate => 'has_is',
    reader => '_get_is',
    writer => '_set_is',
);

#filetest directives the file shouldn't be like
has 'isnt' => (
    is => 'rw',
    isa => 'Directive|ArrayRef[Directive]',
    predicate => 'has_isnt',
    reader => '_get_isnt',
    writer => '_set_isnt',
);

#file owner(s)
has 'owner' => (
    is => 'rw',
    isa => 'Str|ArrayRef[Str]',
    predicate => 'has_owner',
    reader => '_get_owner',
    writer => '_set_owner',
);

#file group(s)
has 'group' => (
    is => 'rw',
    isa => 'Str|ArrayRef[Str]',
    predicate => 'has_group',
    reader => '_get_group',
    writer => '_set_group',
);

#file permissions
has 'perms' => (
    is => 'rw',
    isa => 'Perms|Bitmask|ArrayRef[Perms|Bitmask]',
    predicate => 'has_perms',
    reader => '_get_perms',
    writer => '_set_perms',
);

#where to hold our files before we return them
has 'files' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    writer => '_set_files',
    default => sub { [] },
);


sub BUILD {
    my $self = shift;
    
    $self->like($self->like()) if $self->has_like(); #like
    $self->unlike($self->unlike()) if $self->has_unlike(); #unlike
    $self->dirs($self->dirs()) if $self->has_dirs(); #dirs
    $self->ext($self->ext()) if $self->has_ext(); #ext
    $self->subs($self->subs()) if $self->has_subs(); #subs
    $self->size($self->size()) if $self->has_size(); #size
    $self->changed($self->changed()) if $self->has_changed(); #changed
    $self->modified($self->modified()) if($self->has_modified()); #modified
    $self->accessed($self->accessed()) if $self->has_accessed(); #accessed
    $self->is($self->is()) if $self->has_is(); #is
    $self->isnt($self->isnt()) if $self->has_isnt(); #isnt
    $self->owner($self->owner()) if $self->has_owner(); #owner
    $self->group($self->group()) if $self->has_group(); #group
    $self->perms($self->perms()) if $self->has_perms(); #perms
}


sub dirs {
    my $self = shift;
    my $dirs = shift;
    
    if(!defined($dirs)) {
        return $self->_get_dirs();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str')->check($dirs)) {
        return $self->_set_dirs([$dirs]);
    } else { 
        return $self->_set_dirs($dirs);
    }
}


sub ext {
    my $self = shift;
    my $ext = shift;
    
    if(!defined($ext)) {
        return $self->_get_ext();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str')->check($ext)) {
        return $self->_set_ext([$ext]);
    } else {
        return $self->_set_ext($ext);
    }
}


sub subs {
    my $self = shift;
    my $subs = shift;
    
    if(!defined($subs)) {
        return $self->_get_subs();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('CodeRef')->check($subs)) {
        return $self->_set_subs([$subs]);
    } else {
        return $self->_set_subs($subs);
    }
}


sub size {
    my $self = shift;
    my $size = shift;
    
    if(!defined($size)) {
        return $self->_get_size();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Size')->check($size)) {
        return $self->_set_size([$size]);
    } else {
        return $self->_set_size($size);
    }
}


sub changed {
    my $self = shift;
    my $changed = shift;

    if(!defined($changed)) {
        return $self->_get_changed();
    }

    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Date')->check($changed)) {
        return $self->_set_changed([$changed]);
    } else {
        return $self->_set_changed($changed);
    }
}


sub modified {
    my $self = shift;
    my $modified = shift;

    if(!defined($modified)) {
        return $self->_get_modified();
    }

    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Date')->check($modified)) {
        return $self->_set_modified([$modified]);
    } else {
        return $self->_set_modified($modified);
    }
}


sub accessed {
    my $self = shift;
    my $accessed = shift;

    if(!defined($accessed)) {
        return $self->_get_accessed();
    }

    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Date')->check($accessed)) {
        return $self->_set_accessed([$accessed]);
    } else {
        return $self->_set_accessed($accessed);
    }
}


sub is {
    my $self = shift;
    my $is = shift;
    
    if(!defined($is)) {
        return $self->_get_is();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Directive')->check($is)) {
        $self->_set_is([$is]);
    } else {
        return $self->_set_is($is);
    }
}


sub isnt {
    my $self = shift;
    my $isnt = shift;
    
    if(!defined($isnt)) {
        return $self->_get_isnt();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Directive')->check($isnt)) {
        $self->_set_isnt([$isnt]);
    } else {
        return $self->_set_isnt($isnt);
    }
}


sub owner {
    my $self = shift;
    my $owner = shift;
    
    if (!defined($owner)) {
        return $self->_get_owner();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str')->check($owner)) {
        return $self->_set_owner([$owner]);
    } else {
        return $self->_set_owner($owner);
    }
}


sub group {
    my $self = shift;
    my $group = shift;
    
    if (!defined($group)) {
        return $self->_get_group();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str')->check($group)) {
        return $self->_set_group([$group]);
    } else {
        return $self->_set_group($group);
    }
}


sub perms {
    my $self = shift;
    my $perms = shift;
    
    if(!defined($perms)) {
        return $self->_get_perms();
    }
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Perms')->check($perms)
    || Moose::Util::TypeConstraints::find_or_parse_type_constraint('Bitmask')->check($perms)) {
        return $self->_set_perms([$perms]);
    } else {
        return $self->_set_perms($perms);
    }
}


sub recurse {
    my $self = shift;
    my $recurse = shift;
    
    if(!defined($recurse)) {
        return $self->_get_recurse();
    }
    
    return $self->_set_recurse($recurse);
}


sub like {
    my $self = shift;
    my $like = shift;
    
    if(!defined($like)) {
        return $self->_get_like();
    }
    
    return $self->_set_like(_like_processor($like));
}


sub unlike {
    my $self = shift;
    my $unlike = shift;
    
    if(!defined($unlike)) {
        return $self->_get_unlike();
    }
    
    return $self->_set_unlike(_like_processor($unlike));
}

sub _like_processor {
    my ($like) = @_;
    
    if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str')->check($like)) {
        #convert to regex, and put in a one-element arrayref
        $like = [glob_to_regex($like)];
    } elsif(Moose::Util::TypeConstraints::find_or_parse_type_constraint('RegexpRef')->check($like)) {
        #convert to a one-element arrayref
       $like = [$like];
    } elsif(Moose::Util::TypeConstraints::find_or_parse_type_constraint('ArrayRef')->check($like)) {
        #check each element in the array ref, and make them all regexen
        for(my $i = 0; $i <= $#{$like}; ++$i) {
            if(Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str')->check($like->[$i])) {
                $like->[$i] = glob_to_regex($like->[$i]);
            }
        }
    } else {
        #should never happen
        Carp::croak("Invalid type encountered for an element of like with value $like");
    }
    
    return $like;
}


sub find {
    my $self = shift;
    
    my @files = ();
    my @df = ();
    my $dh;
    my @dirs;
    if(defined($self->dirs())) {
        @dirs = @{$self->dirs()};
    } else {
        @dirs = ();
    }
    
    #don't repeat ourselves
    my %found_dirs = ();
    
    #consider each directory
    while(my $dir = shift @dirs) {
        
        #don't repeat ourselves
        next if defined($found_dirs{$dir});
        $found_dirs{$dir} = 1;
        
        #read the files from the directory, getting rid of . and ..
        opendir($dh, $dir) or Carp::croak "Could not open directory $dir for reading\n"; #should I warn here?
        @df = grep { $_ !~ /^\.$/ && $_ !~ /^\.\.$/ } readdir($dh);
        
        #append the directory name to the files
        for(my $i = 0; $i <= $#df; ++$i) {
            if($dir =~ m!/$!) {
                $df[$i] = $dir.$df[$i];
            } else {
                $df[$i] = $dir.'/'.$df[$i];
            }
        }
        
        #test each file
        foreach my $file (@df) {
            if($self->_test_like($file)
            && $self->_test_unlike($file)
            && $self->_test_ext($file)
            && $self->_test_subs($file)
            && $self->_test_size($file)
            && $self->_test_changed($file)
            && $self->_test_modified($file)
            && $self->_test_accessed($file)
            && $self->_test_is($file)
            && $self->_test_isnt($file)
            && $self->_test_owner($file)
            && $self->_test_group($file)
            && $self->_test_perms($file)) {
                push(@files, $file);
            }
            
            if($self->recurse() && -d $file) {
                push(@dirs, $file);
            }
        }
    }
    
    $self->_set_files(\@files);
        
    #return files found
    return @files;
}

sub _test_like {
    my ($self, $file) = @_;
    
    if(!$self->has_like()) { return 1; }
    
    foreach my $re (@{$self->like()}) {
        return 0 if $file !~ $re;
    }
    
    return 1;
}

sub _test_unlike {
    my ($self, $file) = @_;
    
    if(!$self->has_unlike()) { return 1; }
    
    foreach my $re (@{$self->unlike()}) {
        return 0 if $file =~ $re;
    }
    
    return 1;
}

sub _test_ext { #ANY extension
    my ($self, $file) = @_;
    
    if(!$self->has_ext()) { return 1; }
    
    foreach my $ext (@{$self->ext()}) {
        return 1 if $file =~ qr/${ext}$/;
    }
    
    return 0;
}

sub _test_subs {
    my ($self, $file) = @_;
    
    if(!$self->has_subs()) { return 1; }
    
    foreach my $sub (@{$self->subs()}) {
        return 0 if !&$sub($file);
    }
    
    return 1;
}

sub _test_size {
    my ($self, $file) = @_;
    
    if(!$self->has_size()) { return 1; }
    
    my ($f) = File::Util->new();
    
    foreach my $size (@{$self->size()}) {
        return 0 if !Number::Compare->new($size)->test($f->size($file));
    }
    
    return 1;
}

sub _test_changed {
    my ($self, $file) = @_;
    
    if(!$self->has_changed()) { return 1; }
    
    my ($f) = File::Util->new();
    
    foreach my $date (@{$self->changed()}) {
        return 0 if !Number::Compare::Date->new($date)->test($f->last_changed($file));
    }
    
    return 1;
}

sub _test_modified {
    my ($self, $file) = @_;
    
    if(!$self->has_modified()) { return 1; }
    
    my ($f) = File::Util->new();
    
    foreach my $date (@{$self->modified()}) {
        return 0 if !Number::Compare::Date->new($date)->test($f->last_modified($file));
    }
    
    return 1;
}

sub _test_accessed {
    my ($self, $file) = @_;
    
    if(!$self->has_accessed()) { return 1; }
    
    my ($f) = File::Util->new();
    
    foreach my $date (@{$self->accessed()}) {
        return 0 if !Number::Compare::Date->new($date)->test($f->last_access($file));
    }
    
    return 1;
}

sub _test_is {
    my ($self, $file) = @_;
    
    if(!$self->has_is()) { return 1; }
    
    foreach my $directive (@{$self->is()}) {
        if($directive eq 'readable') {
            return 0 if !-r $file;
        } elsif($directive eq 'r_readable') {
            return 0 if !-R $file;
        } elsif($directive eq 'writable') {
            return 0 if !-w $file;
        } elsif($directive eq 'r_writable') {
            return 0 if !-W $file;
        } elsif($directive eq 'executable') {
            return 0 if !-x $file;
        } elsif($directive eq 'r_executable') {
            return 0 if !-X $file;
        } elsif($directive eq 'owned') {
            return 0 if !-o $file;
        } elsif($directive eq 'r_owned') {
            return 0 if !-O $file;
        } elsif($directive eq 'exists') {
            return 0 if !-e $file;
        } elsif($directive eq 'file') {
            return 0 if !-f $file;
        } elsif($directive eq 'empty') {
            return 0 if !-z $file;
        } elsif($directive eq 'directory') {
            return 0 if !-d $file;
        } elsif($directive eq 'nonempty') {
            return 0 if !-s $file;
        } elsif($directive eq 'symlink') {
            return 0 if !-l $file;
        } elsif($directive eq 'fifo') {
            return 0 if !-p $file;
        } elsif($directive eq 'setuid') {
            return 0 if !-u $file;
        } elsif($directive eq 'socket') {
            return 0 if !-S $file;
        } elsif($directive eq 'setgid') {
            return 0 if !-g $file;
        } elsif($directive eq 'block') {
            return 0 if !-b $file;
        } elsif($directive eq 'sticky') {
            return 0 if !-k $file;
        } elsif($directive eq 'character') {
            return 0 if !-c $file;
        } elsif($directive eq 'tty') {
            return 0 if !-t $file;
        } elsif($directive eq 'modified') {
            return 0 if !-M $file;
        } elsif($directive eq 'accessed') {
            return 0 if !-A $file;
        } elsif($directive eq 'ascii') {
            return 0 if !-T $file;
        } elsif($directive eq 'changed') {
            return 0 if !-C $file;
        } elsif($directive eq 'binary') {
            return 0 if !-B $file;
        }
    }
    
    return 1;
}

sub _test_isnt {
    my ($self, $file) = @_;
    
    if(!$self->has_isnt()) { return 1; }
    
    foreach my $directive (@{$self->isnt()}) {
        if($directive eq 'readable') {
            return 0 if -r $file;
        } elsif($directive eq 'r_readable') {
            return 0 if -R $file;
        } elsif($directive eq 'writable') {
            return 0 if -w $file;
        } elsif($directive eq 'r_writable') {
            return 0 if -W $file;
        } elsif($directive eq 'executable') {
            return 0 if -x $file;
        } elsif($directive eq 'r_executable') {
            return 0 if -X $file;
        } elsif($directive eq 'owned') {
            return 0 if -o $file;
        } elsif($directive eq 'r_owned') {
            return 0 if -O $file;
        } elsif($directive eq 'exists') {
            return 0 if -e $file;
        } elsif($directive eq 'file') {
            return 0 if -f $file;
        } elsif($directive eq 'empty') {
            return 0 if -z $file;
        } elsif($directive eq 'directory') {
            return 0 if -d $file;
        } elsif($directive eq 'nonempty') {
            return 0 if -s $file;
        } elsif($directive eq 'symlink') {
            return 0 if -l $file;
        } elsif($directive eq 'fifo') {
            return 0 if -p $file;
        } elsif($directive eq 'setuid') {
            return 0 if -u $file;
        } elsif($directive eq 'socket') {
            return 0 if -S $file;
        } elsif($directive eq 'setgid') {
            return 0 if -g $file;
        } elsif($directive eq 'block') {
            return 0 if -b $file;
        } elsif($directive eq 'sticky') {
            return 0 if -k $file;
        } elsif($directive eq 'character') {
            return 0 if -c $file;
        } elsif($directive eq 'tty') {
            return 0 if -t $file;
        } elsif($directive eq 'modified') {
            return 0 if -M $file;
        } elsif($directive eq 'accessed') {
            return 0 if -A $file;
        } elsif($directive eq 'ascii') {
            return 0 if -T $file;
        } elsif($directive eq 'changed') {
            return 0 if -C $file;
        } elsif($directive eq 'binary') {
            return 0 if -B $file;
        }
    }
    
    return 1;
}

sub _test_owner { #ANY
    my ($self, $file) = @_;
    
    if(!$self->has_owner()) { return 1; }
    
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
    my $name = getpwuid($uid);
    
    foreach my $owner (@{$self->owner()}) {
        return 1 if $owner eq $uid || $owner eq $name;
    }
    
    return 0;
}

sub _test_group { #ANY
    my ($self, $file) = @_;
    
    if(!$self->has_group()) { return 1; }
    
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
    my $name = getgrgid($gid);
    
    foreach my $group (@{$self->group()}) {
        return 1 if $group eq $gid || $group eq $name;
    }
    
    return 0;
}

sub _test_perms { #ANY
    my ($self, $file) = @_;
    
    if(!$self->has_perms()) { return 1; }
    
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
    $mode = $mode & 07777;
    $mode = sprintf('%03o', $mode);
    
    foreach my $perm (@{$self->perms()}) {
        return 1 if $mode == $perm || $mode eq _perm_string_to_octal($perm);
    }
    
    return 0;
}

sub _perm_string_to_octal {
    my $str = shift;
    
    if($str =~ m/^([r-][w-][x-])([r-][w-][x-])([r-][w-][x-])$/) {
    
        my $owner = $1;
        my $group = $2;
        my $other = $3;
        
        my $vals = {
            '---' => 0,
            '--x' => 1,
            '-w-' => 2,
            '-wx' => 3,
            'r--' => 4,
            'r-x' => 5,
            'rw-' => 6,
            'rwx' => 7,
        };
        
        return $vals->{$owner} * 100 + $vals->{$group} * 10 + $vals->{$other};
    }
    
    return $str;
}



no Moose;

1;

__END__
=pod

=head1 NAME

File::Find::Declare - File::Find, declaratively

=head1 VERSION

version 0.62

=head1 SYNOPSIS

  use File::Find::Declare;
  
  my $fff = File::Find::Declare->new({ like => qr/foo/, dirs => '/home' });
  my @files = $fff->find();

=head1 DESCRIPTION

File::Find::Declare is an object-oriented way to go about find files. With
many ways to specify what your are looking for in a file, File::Find::Declare
is both simple and powerful. Configuration may be passed at construction
time, or it may be set after a new object is created, or set at construction
time and then altered later, should you wish to set defaults and then change
them.

File::Find::Declare is an alternative to L<File::Find> and L<File::Find::Rule>. It is
meant to be much simpler than File::Find and behaves differently then 
File::Find::Rule.

=head1 Getting Started with File::Find::Declare

File::Find::Declare supports several ways of setting up your search options, and
many more ways of specifying file attributes to search for. To use File::Find::Declare,
simply,

  use File::Find::Declare;

No methods are exported. This module is meant to be used solely in an
object-oriented manner. You can then specify what you want to search for:

  my $sp = { like => qr/foo/, unlike => qr/bar/, dirs => [ '/home', '/etc' ] };

This will search for files whose names contain I<foo>, don't contain I<bar>, and
which are located in either I</home> or I</etc>. Create a File::Find::Declare object,
like so:

  my $fff = File::Find::Declare->new($sp);

Although you could have (of course) simply done this:

  my $fff = File::Find::Declare->new({
      like => qr/foo/,
      unlike => qr/bar/,
      dirs => [ '/home', '/etc' ]
  });

And cut out the use of the intermediate variable C<$sp> entirely. To find your files,
call C<find()>:

  my @files = $fff->find();

And that's it. To recap:

  use File::Find::Declare;
  my $sp = { like => qr/foo/, unlike => qr/bar/, dirs => [ '/home', '/etc' ] };
  my $fff = File::Find::Declare->new($sp);
  my @files = $fff->find();

=head1 Search Options

File::Find::Declare has many possible search options. What follows is a listing of all
those options, followed by a discussion of them.

  my $sp = {
      like => qr/foo/,
      unlike => qr/bar/,
      dirs => '/home',
      ext => '.txt',
      subs => sub { $_[0] =~ m/baz/ },
      size => '>10K',
      changed => '<2010-01-30',
      modified => '<2010-01-30',
      accessed => '>2010-01-30',
      recurse => 1,
      is => 'readable',
      isnt => 'executable',
      owner => 'foo',
      group => 'none',
      perms => 'wr-wr-wr-',
  };

=head2 Specifying like

C<like> is how you specify what a filename should look like. You may use regular
expressions (using C<qr//>), globs (as strings), or an array reference containing
regular expressions and/or globs. If you provide an array reference, the filename
must match ALL the given regexen or globs.

=head2 Specifying unlike

C<unlike> is just the opposite of like. It specifies what a filename should not
look like. Again, you may use regular expressions (using C<qr//>), globs (as strings),
or an array reference containing regular expressions and/or globs. If you provide an array
reference, the filename must match NONE of the given regexen or globs.

=head2 Specifying dirs

C<dirs> is how you specify where to look. It may be either a string containing a single
directory name, or an array reference of directories to use.

=head2 Specifying ext

C<ext> allows you to search for files by extension. You may specify either a single string
containing an extension, or an array reference of such extensions. If you provide an array
reference, the filename will match ANY extension.

=head2 Specifying subs

C<subs> gives you the ability to define your own functions to inspect each filename. It
expects either a single code reference, or an array reference containing code references.
If you provide an array reference, ALL functions must return true for a given file for it
to be considered "matched".

=head2 Specifying size

C<size> uses L<Number::Compare> semantics to examine the file size. You are therefore free
to specify things like C<1024>, C<2K>, C<<=2048>, etc. It expects either a single string
containing a size specification, or an array reference containing such specifications. If
you provide an array reference, a file's size must match ALL the given constraints.

=head2 Specifying changed

C<changed> uses L<Number::Compare::Date> semantics to allow you to search based on a file's
inode changed time. You may use anything that L<Date::Parse> understands to specify a date,
as well as comparison operators to specify a relationship to that date. You should provide
either a single string containing such a specification, or an array reference of such
specifications. If you provide an array reference, a file's changed time must match ALL of
the given conditions.

=head2 Specifying modified

C<modified> uses L<Number::Compare::Date> semantics to allow you to search based on a file's
last modified time. You may use anything that L<Date::Parse> understands to specify a date,
as well as comparison operators to specify a relationship to that date. You should provide
either a single string containing such a specification, or an array reference of such
specifications. If you provide an array reference, a file's modified time must match ALL of
the given conditions.

=head2 Specifying accessed

C<accessed> uses L<Number::Compare::Date> semantics to allow you to search based on a file's
last accessed time. You may use anything that L<Date::Parse> understands to specify a date,
as well as comparison operators to specify a relationship to that date. You should provide
either a single string containing such a specification, or an array reference of such
specifications. If you provide an array reference, a file's accessed time must match ALL of
the given conditions.

=head2 Specifying recurse

C<recurse> indicates to the module whether or not it should recursively process any directories
it has found. The current behavior is to inspect all directories, not just those that would
match the given predicates. In the future, configuration options will be available to modify this
behavior.

=head2 Specifying is

C<is> allows you to test files using Perl's standard filetest operators. Each is given a string alias,
as described below:

  Alias:         Operator:
  readable       -r
  r_readable     -R
  writable       -w
  r_writable     -W
  executable     -x
  r_executable   -X
  owned          -o
  r_owned        -O
  exists         -e
  file           -f
  empty          -z
  directory      -d
  nonempty       -s
  symlink        -l
  fifo           -p
  setuid         -u
  socket         -S
  setgid         -g
  block          -b
  sticky         -k
  character      -c
  tty            -t
  modified       -M
  accessed       -A
  ascii          -T
  changed        -C
  binary         -B

C<is> expects either a string containing a single alias, or an array reference
containing a list of such aliases. If you specify an array reference, any file
must pass ALL of the given tests to be considered "matched".

=head2 Specifying isnt

C<isnt> is just the opposite of C<is>. C<isnt> expects either a string containing
a single alias, or an array reference containing a list of such aliases. If you
specify an array reference, any file must pass NONE of the given tests to be
considered "matched". See also L<Specifying is>.

=head2 Specifying owner

C<owner> lets you search for a file based on it's owner. It expects either a
string containing a username, a user's ID, or an array reference containing
either of these things. If you specify an array reference, if a file has
ANY matching owner, it will be returned.

=head2 Specifying group

C<group> lets you search for a file based on it's group. It expects either a
string containing a groupname, a group's ID, or an array reference containing
either of these things. If you specify an array reference, if a file has
ANY matching group, it will be returned.

=head2 Specifying perms

C<perms> gives you the ability to search for a file based on its permissions.
You may specify a string such as C<rwxrw-r--> or three digits such as C<752>,
or an array reference containing either of these. If you specify an array
reference, a file that matches ANY of the permissions given will be considered
matched.

=head1 METHODS

=head2 dirs

The method C<dirs> allows you to set the directories to search in after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the directories to search in. See also L<Specifying dirs>.

=head2 ext

The method C<ext> allows you to set the extensions to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the extensions to search for. See also L<Specifying ext>.

=head2 subs

The method C<subs> allows you to set the subroutines to search with after the
object has been created. It expects an array reference, or a single CodeRef.
If called with no arguments, it will return an array reference containing
the subroutines currently set.  See also L<Specifying subs>.

=head2 size

The method C<ext> allows you to set the file size(s) to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the file size(s) to search for. See also L<Specifying size>.

=head2 changed

The method C<changed> allows you to set the changed time to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the changed time to search for. See also L<Specifying changed>.

=head2 modified

The method C<modified> allows you to set the modified time to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the modified time to search for. See also L<Specifying modified>.

=head2 accessed

The method C<accessed> allows you to set the accessed time to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the accessed time to search for. See also L<Specifying accessed>.

=head2 is

The method C<is> allows you to set the file tests to search with after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the file tests to search with. See also L<Specifying is>.

=head2 isnt

The method C<isnt> allows you to set the file tests to search against after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the file tests to search against. See also L<Specifying isnt>.

=head2 owner

The method C<owner> allows you to set the owner(s) to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the owner(s) to search for. See also L<Specifying owner>.

=head2 group

The method C<group> allows you to set the group(s) to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the group(s) to search for. See also L<Specifying group>.

=head2 perms

The method C<perms> allows you to set the permuission(s) to search for after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the permission(s) to search for. See also L<Specifying perms>.

=head2 recurse

The method C<recurse> allows you to set the recursion property after the
object has been created. It expects a single number, 0 for false, any other for true.
If called with no arguments, it will return whatever recurse is currently set
to. See also L<Specifying recurse>.

=head2 like

The method C<like> allows you to set the filename tests to search with after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the filename tests to search with. See also L<Specifying like>.

=head2 unlike

The method C<unlike> allows you to set the filename tests to search against after the
object has been created. It expects an array reference, or a single string.
If called with no arguments, it will return an array reference containing
the filename tests to search against. See also L<Specifying unlike>.

=head2 find

Invoking C<find> will cause the module to search for files based on the
currently set options. It expects no arguments and returns an array of
filenames.

=for Pod::Coverage   BUILD

=head1 REPOSITORY

The source code repository for this project is located at:

  http://github.com/f0rk/file-find-declare

=head1 AUTHOR

  Ryan P. Kelly <rpkelly@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Ryan P. Kelly.

This is free software, licensed under:

  The MIT (X11) License

=cut

