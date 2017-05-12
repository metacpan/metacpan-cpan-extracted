#       $Id: /mirror/lab/perl/File-Find-Rule/lib/File/Find/Rule.pm 2102 2006-06-01T15:39:03.942922Z richardc  $

package File::Find::Object::Rule;

use strict;
use warnings;

use 5.008;

use vars qw/$VERSION $AUTOLOAD/;
use File::Spec;
use Text::Glob 'glob_to_regex';
use Number::Compare;
use Carp qw/croak/;
use File::Find::Object; # we're only wrapping for now
use File::Basename;
use Cwd;           # 5.00503s File::Find goes screwy with max_depth == 0

$VERSION = '0.0306';

use Class::XSAccessor
    accessors => {
        "extras" => "extras",
        "finder" => "finder",
        "_match_cb" => "_match_cb",
        "rules" => "rules",
        "_relative" => "_relative",
        "_subs" => "_subs",
        "_maxdepth" => "_maxdepth",
        "_mindepth" => "_mindepth",
    }
    ;

# we'd just inherit from Exporter, but I want the colon
sub import {
    my $pkg = shift;
    my $to  = caller;
    for my $sym ( qw( find rule ) ) {
        no strict 'refs';
        *{"$to\::$sym"} = \&{$sym};
    }
    for (grep /^:/, @_) {
        my ($extension) = /^:(.*)/;
        eval "require File::Find::Object::Rule::$extension";
        croak "couldn't bootstrap File::Find::Object::Rule::$extension: $@" if $@;
    }
}

=encoding utf8

=head1 NAME

File::Find::Object::Rule - Alternative interface to File::Find::Object

=head1 SYNOPSIS

  use File::Find::Object::Rule;
  # find all the subdirectories of a given directory
  my @subdirs = File::Find::Object::Rule->directory->in( $directory );

  # find all the .pm files in @INC
  my @files = File::Find::Object::Rule->file()
                              ->name( '*.pm' )
                              ->in( @INC );

  # as above, but without method chaining
  my $rule =  File::Find::Object::Rule->new;
  $rule->file;
  $rule->name( '*.pm' );
  my @files = $rule->in( @INC );

=head1 DESCRIPTION

File::Find::Object::Rule is a friendlier interface to L<File::Find::Object> .
It allows you to build rules which specify the desired files and directories.

B<WARNING> : This module is a fork of version 0.30 of L<File::Find::Rule>
(which has been unmaintained for several years as of February, 2009), and may
still have some bugs due to its reliance on File::Find'isms. As such it is
considered Alpha software. Please report any problems with
L<File::Find::Object::Rule> to its RT CPAN Queue.

=cut

# the procedural shim

*rule = \&find;
sub find {
    my $object = __PACKAGE__->new();
    my $not = 0;

    while (@_) {
        my $method = shift;
        my @args;

        if ($method =~ s/^\!//) {
            # jinkies, we're really negating this
            unshift @_, $method;
            $not = 1;
            next;
        }
        unless (defined prototype $method) {
            my $args = shift;
            @args = ref $args eq 'ARRAY' ? @$args : $args;
        }
        if ($not) {
            $not = 0;
            @args = ref($object)->new->$method(@args);
            $method = "not";
        }

        my @return = $object->$method(@args);
        return @return if $method eq 'in';
    }
    $object;
}


=head1 METHODS

=over

=item C<new>

A constructor.  You need not invoke C<new> manually unless you wish
to, as each of the rule-making methods will auto-create a suitable
object if called as class methods.

=cut

sub new {
    # We need this to maintain compatibility with File-Find-Object.
    # However, Randal Schwartz recommends against this practice in general:
    # http://www.stonehenge.com/merlyn/UnixReview/col52.html
    my $referent = shift;
    my $class = ref $referent || $referent;

    return
    bless {
        rules    => [],  # [0]
        _subs     => [],  # [1]
        iterator => [],
        extras   => {},
        _maxdepth => undef,
        _mindepth => undef,
        _relative => 0,
    }, $class;
}

sub _force_object {
    my $object = shift;
    if (! ref($object))
    {
        $object = $object->new();
    }
    return $object;
}

=back

=head2 finder

The L<File::Find::Object> finder instance itself.

=head2 my @rules = @{$ffor->rules()};

The rules to match against. For internal use only.

=head2 Matching Rules

=over

=item C<name( @patterns )>

Specifies names that should match.  May be globs or regular
expressions.

 $set->name( '*.mp3', '*.ogg' ); # mp3s or oggs
 $set->name( qr/\.(mp3|ogg)$/ ); # the same as a regex
 $set->name( 'foo.bar' );        # just things named foo.bar

=cut

sub _flatten {
    my @flat;
    while (@_) {
        my $item = shift;
        ref $item eq 'ARRAY' ? push @_, @{ $item } : push @flat, $item;
    }
    return @flat;
}

sub _add_rule {
    my $self = shift;
    my $new_rule = shift;

    push @{$self->rules()}, $new_rule;

    return;
}

sub name {
    my $self = _force_object shift;
    my @names = map { ref $_ eq "Regexp" ? $_ : glob_to_regex $_ } _flatten( @_ );

    $self->_add_rule(
        {
            rule => 'name',
            code => join( ' || ', map { "m($_)" } @names ),
            args => \@_,
        }
    );

    $self;
}

=item -X tests

Synonyms are provided for each of the -X tests. See L<perlfunc/-X> for
details.  None of these methods take arguments.

  Test | Method               Test |  Method
 ------|-------------        ------|----------------
   -r  |  readable             -R  |  r_readable
   -w  |  writeable            -W  |  r_writeable
   -w  |  writable             -W  |  r_writable
   -x  |  executable           -X  |  r_executable
   -o  |  owned                -O  |  r_owned
       |                           |
   -e  |  exists               -f  |  file
   -z  |  empty                -d  |  directory
   -s  |  nonempty             -l  |  symlink
       |                       -p  |  fifo
   -u  |  setuid               -S  |  socket
   -g  |  setgid               -b  |  block
   -k  |  sticky               -c  |  character
       |                       -t  |  tty
   -M  |  modified                 |
   -A  |  accessed             -T  |  ascii
   -C  |  changed              -B  |  binary

Though some tests are fairly meaningless as binary flags (C<modified>,
C<accessed>, C<changed>), they have been included for completeness.

 # find nonempty files
 $rule->file,
      ->nonempty;

=cut

use vars qw( %X_tests );
%X_tests = (
    -r  =>  readable           =>  -R  =>  r_readable      =>
    -w  =>  writeable          =>  -W  =>  r_writeable     =>
    -w  =>  writable           =>  -W  =>  r_writable      =>
    -x  =>  executable         =>  -X  =>  r_executable    =>
    -o  =>  owned              =>  -O  =>  r_owned         =>

    -e  =>  exists             =>  -f  =>  file            =>
    -z  =>  empty              =>  -d  =>  directory       =>
    -s  =>  nonempty           =>  -l  =>  symlink         =>
                               =>  -p  =>  fifo            =>
    -u  =>  setuid             =>  -S  =>  socket          =>
    -g  =>  setgid             =>  -b  =>  block           =>
    -k  =>  sticky             =>  -c  =>  character       =>
                               =>  -t  =>  tty             =>
    -M  =>  modified                                       =>
    -A  =>  accessed           =>  -T  =>  ascii           =>
    -C  =>  changed            =>  -B  =>  binary          =>
   );

for my $test (keys %X_tests) {
    my $sub = eval 'sub () {
        my $self = _force_object shift;
        $self->_add_rule({
            code => "' . $test . ' \$path",
            rule => "'.$X_tests{$test}.'",
        });
        $self;
    } ';
    no strict 'refs';
    *{ $X_tests{$test} } = $sub;
}


=item stat tests

The following C<stat> based methods are provided: C<dev>, C<ino>,
C<mode>, C<nlink>, C<uid>, C<gid>, C<rdev>, C<size>, C<atime>,
C<mtime>, C<ctime>, C<blksize>, and C<blocks>.  See L<perlfunc/stat>
for details.

Each of these can take a number of targets, which will follow
L<Number::Compare> semantics.

 $rule->size( 7 );         # exactly 7
 $rule->size( ">7Ki" );    # larger than 7 * 1024 * 1024 bytes
 $rule->size( ">=7" )
      ->size( "<=90" );    # between 7 and 90, inclusive
 $rule->size( 7, 9, 42 );  # 7, 9 or 42

=cut

use vars qw( @stat_tests );
@stat_tests = qw( dev ino mode nlink uid gid rdev
                  size atime mtime ctime blksize blocks );
{
    my $i = 0;
    for my $test (@stat_tests) {
        my $index = $i++; # to close over
        my $sub = sub {
            my $self = _force_object shift;

            my @tests = map { Number::Compare->parse_to_perl($_) } @_;

            $self->_add_rule({
                rule => $test,
                args => \@_,
                code => 'do { my $val = (stat $path)['.$index.'] || 0;'.
                  join ('||', map { "(\$val $_)" } @tests ).' }',
            });
            $self;
        };
        no strict 'refs';
        *$test = $sub;
    }
}

=item C<any( @rules )>

=item C<or( @rules )>

Allows shortcircuiting boolean evaluation as an alternative to the
default and-like nature of combined rules.  C<any> and C<or> are
interchangeable.

 # find avis, movs, things over 200M and empty files
 $rule->any( File::Find::Object::Rule->name( '*.avi', '*.mov' ),
             File::Find::Object::Rule->size( '>200M' ),
             File::Find::Object::Rule->file->empty,
           );

=cut

sub any {
    my $self = _force_object shift;
    my @rulesets = @_;

    $self->_add_rule({
        rule => 'any',
        code => '(' . join( ' || ', map {
            "( " . $_->_compile($self->_subs()) . " )"
        } @rulesets ) . ")",
        args => \@rulesets,
    });
    $self;
}

*or = \&any;

=item C<none( @rules )>

=item C<not( @rules )>

Negates a rule.  (The inverse of C<any>.)  C<none> and C<not> are
interchangeable.

  # files that aren't 8.3 safe
  $rule->file
       ->not( $rule->new->name( qr/^[^.]{1,8}(\.[^.]{0,3})?$/ ) );

=cut

sub not {
    my $self = _force_object shift;
    my @rulesets = @_;

    $self->_add_rule({
        rule => 'not',
        args => \@rulesets,
        code => '(' . join ( ' && ', map {
            "!(". $_->_compile($self->_subs()) . ")"
        } @_ ) . ")",
    });
    $self;
}

*none = \&not;

=item C<prune>

Traverse no further.  This rule always matches.

=cut

sub prune () {
    my $self = _force_object shift;

    $self->_add_rule(
        {
            rule => 'prune',
            code => 'do { $self->finder->prune(); 1 }'
        },
    );

    return $self;
}

=item C<discard>

Don't keep this file.  This rule always matches.

=cut

sub discard () {
    my $self = _force_object shift;

    $self->_add_rule({
        rule => 'discard',
        code => '$discarded = 1',
    });

    return $self;
}

=item C<exec( \&subroutine( $shortname, $path, $fullname ) )>

Allows user-defined rules.  Your subroutine will be invoked with parameters of
the name, the path you're in, and the full relative filename.
In addition, C<$_> is set to the current short name, but its use is
discouraged since as opposed to File::Find::Rule, File::Find::Object::Rule
does not cd to the containing directory.

Return a true value if your rule matched.

 # get things with long names
 $rules->exec( sub { length > 20 } );

=cut

sub exec {
    my $self = _force_object shift;
    my $code = shift;

    $self->_add_rule(
        {
            rule => 'exec',
            code => $code,
        }
    );

    return $self;
}

=item ->grep( @specifiers );

Opens a file and tests it each line at a time.

For each line it evaluates each of the specifiers, stopping at the
first successful match.  A specifier may be a regular expression or a
subroutine.  The subroutine will be invoked with the same parameters
as an ->exec subroutine.

It is possible to provide a set of negative specifiers by enclosing
them in anonymous arrays.  Should a negative specifier match the
iteration is aborted and the clause is failed.  For example:

 $rule->grep( qr/^#!.*\bperl/, [ sub { 1 } ] );

Is a passing clause if the first line of a file looks like a perl
shebang line.

=cut

sub grep {
    my $self = _force_object shift;
    my @pattern = map {
        ref $_
          ? ref $_ eq 'ARRAY'
            ? map { [ ( ref $_ ? $_ : qr/$_/ ) => 0 ] } @$_
            : [ $_ => 1 ]
          : [ qr/$_/ => 1 ]
      } @_;

    $self->exec( sub {
        local *FILE;
        open FILE, $self->finder->item() or return;
        local ($_, $.);
        while (<FILE>) {
            for my $p (@pattern) {
                my ($rule, $ret) = @$p;
                return $ret
                  if ref $rule eq 'Regexp'
                    ? /$rule/
                      : $rule->(@_);
            }
        }
        return;
    } );
}

=item C<maxdepth( $level )>

Descend at most C<$level> (a non-negative integer) levels of directories
below the starting point.

May be invoked many times per rule, but only the most recent value is
used.

=item C<mindepth( $level )>

Do not apply any tests at levels less than C<$level> (a non-negative
integer).

=item C<extras( \%extras )>

Specifies extra values to pass through to C<File::File::find> as part
of the options hash.

For example this allows you to specify following of symlinks like so:

 my $rule = File::Find::Object::Rule->extras({ follow => 1 });

May be invoked many times per rule, but only the most recent value is
used.

=cut

sub maxdepth {
    my $self = _force_object shift;
    $self->_maxdepth(shift);
    return $self;
}

sub mindepth {
    my $self = _force_object shift;
    $self->_mindepth(shift);
    return $self;
}

=item C<relative>

Trim the leading portion of any path found

=cut

sub relative () {
    my $self = _force_object shift;
    $self->_relative(1);

    return $self;
}

=item C<not_*>

Negated version of the rule.  An effective shortand related to ! in
the procedural interface.

 $foo->not_name('*.pl');

 $foo->not( $foo->new->name('*.pl' ) );

=cut

sub DESTROY {}
sub AUTOLOAD {
    $AUTOLOAD =~ /::not_([^:]*)$/
      or croak "Can't locate method $AUTOLOAD";
    my $method = $1;

    my $sub = sub {
        my $self = _force_object shift;
        $self->not( $self->new->$method(@_) );
    };
    {
        no strict 'refs';
        *$AUTOLOAD = $sub;
    }
    &$sub;
}

=back

=head2 Query Methods

=over

=item C<in( @directories )>

Evaluates the rule, returns a list of paths to matching files and
directories.

=cut


sub _call_find {
    my $self = shift;
    my $paths = shift;

    my $finder = File::Find::Object->new( $self->extras(), @$paths);

    $self->finder($finder);

    return;
}

sub _compile {
    my $self = shift;
    my $subs = shift;

    return '1' unless @{ $self->rules() };

    my $code = join " && ", map {
        if (ref $_->{code}) {
            push @$subs, $_->{code};
            "\$subs->[$#{$subs}]->(\@args) # $_->{rule}\n";
        }
        else {
            "( $_->{code} ) # $_->{rule}\n";
        }
    } @{ $self->rules() };

    return $code;
}

sub in {
    my $self = _force_object shift;
    my @paths = @_;

    $self->start(@paths);

    my @results;

    while (defined(my $match = $self->match()))
    {
        push @results, $match;
    }

    return @results;
}

=item C<start( @directories )>

Starts a find across the specified directories.  Matching items may
then be queried using L</match>.  This allows you to use a rule as an
iterator.

 my $rule = File::Find::Object::Rule->file->name("*.jpeg")->start( "/web" );
 while ( my $image = $rule->match ) {
     ...
 }

=cut


sub start {
    my $self = _force_object shift;
    my @paths = @_;

    my $fragment = $self->_compile($self->_subs());

    my $subs = $self->_subs();

    warn "relative mode handed multiple paths - that's a bit silly\n"
      if $self->_relative() && @paths > 1;

    my $code = 'sub {
        my $path_obj = shift;
        my $path = shift;

        if (!defined($path_obj))
        {
            return;
        }

        $path =~ s#^(?:\./+)+##;
        my $path_dir = dirname($path);
        my $path_base = fileparse($path);
        my @args = ($path_base, $path_dir, $path);
        local $_ = $path_base;
        my $maxdepth = $self->_maxdepth;
        my $mindepth = $self->_mindepth;

        my $comps = $path_obj->full_components();

        my $depth = scalar(@$comps);

        defined $maxdepth && $depth >= $maxdepth
           and $self->finder->prune();

        defined $mindepth && $depth < $mindepth
           and return;

        #print "Testing \'$_\'\n";

        my $discarded;
        return unless ' . $fragment . ';
        return if $discarded;
        return $path;
    }';

    #use Data::Dumper;
    #print Dumper \@subs;
    #warn "Compiled sub: '$code'\n";

    my $callback = eval "$code" or die "compile error '$code' $@";

    $self->_match_cb($callback);
    $self->_call_find(\@paths);

    return $self;
}


=item C<match>

Returns the next file which matches, false if there are no more.

=cut

sub match {
    my $self = _force_object shift;

    my $finder = $self->finder();

    my $match_cb = $self->_match_cb();
    my $preproc_cb = $self->extras()->{'preprocess'};

    while(defined(my $next_obj = $finder->next_obj()))
    {
        if (defined($preproc_cb) && $next_obj->is_dir())
        {
            $finder->set_traverse_to(
                $preproc_cb->(
                        $self,
                        [ @{$finder->get_current_node_files_list()} ]
                )
            );
        }

        if (defined(my $path = $match_cb->($next_obj, $next_obj->path())))
        {
            if ($self->_relative)
            {
                my $comps = $next_obj->full_components();
                if (@$comps)
                {
                    return
                        ($next_obj->is_dir()
                        ? File::Spec->catdir(@$comps)
                        : File::Spec->catfile(@$comps)
                        )
                    ;
                }
            }
            else
            {
                return $path;
            }
        }

    }

    return;
}

1;

__END__

=back

=head2 Extensions

Extension modules are available from CPAN in the File::Find::Object::Rule
namespace.  In order to use these extensions either use them directly:

 use File::Find::Object::Rule::ImageSize;
 use File::Find::Object::Rule::MMagic;

 # now your rules can use the clauses supplied by the ImageSize and
 # MMagic extension

or, specify that File::Find::Object::Rule should load them for you:

 use File::Find::Object::Rule qw( :ImageSize :MMagic );

For notes on implementing your own extensions, consult
L<File::Find::Object::Rule::Extending>

=head2 Further examples

=over

=item Finding perl scripts

 my $finder = File::Find::Object::Rule->or
  (
   File::Find::Object::Rule->name( '*.pl' ),
   File::Find::Object::Rule->exec(
                          sub {
                              if (open my $fh, $_) {
                                  my $shebang = <$fh>;
                                  close $fh;
                                  return $shebang =~ /^#!.*\bperl/;
                              }
                              return 0;
                          } ),
  );

Based upon this message http://use.perl.org/comments.pl?sid=7052&cid=10842

=item ignore CVS directories

 my $rule = File::Find::Object::Rule->new;
 $rule->or($rule->new
                ->directory
                ->name('CVS')
                ->prune
                ->discard,
           $rule->new);

Note here the use of a null rule.  Null rules match anything they see,
so the effect is to match (and discard) directories called 'CVS' or to
match anything.

=back

=head1 TWO FOR THE PRICE OF ONE

File::Find::Object::Rule also gives you a procedural interface.  This is
documented in L<File::Find::Object::Rule::Procedural>

=head1 EXPORTS

=head2 find

=head2 rule

=head1 Tests

=head2 accessed

Corresponds to C<-A>.

=head2 ascii

Corresponds to C<-T>.

=head2 atime

See "stat tests".

=head2 binary

Corresponds to C<-b>.

=head2 blksize

See "stat tests".

=head2 block

Corresponds to C<-b>.

=head2 blocks

See "stat tests".

=head2 changed

Corresponds to C<-C>.

=head2 character

Corresponds to C<-c>.

=head2 ctime

See "stat tests".

=head2 dev

See "stat tests".

=head2 directory

Corresponds to C<-d>.

=head2 empty

Corresponds to C<-z>.

=head2 executable

Corresponds to C<-x>.

=head2 exists

Corresponds to C<-e>.

=head2 fifo

Corresponds to C<-p>.

=head2 file

Corresponds to C<-f>.

=head2 gid

See "stat tests".

=head2 ino

See "stat tests".

=head2 mode

See "stat tests".

=head2 modified

Corresponds to C<-M>.

=head2 mtime

See "stat tests".

=head2 nlink

See "stat tests".

=head2 r_executable

Corresponds to C<-X>.

=head2 r_owned

Corresponds to C<-O>.

=head2 nonempty

A predicate that determines if the file is empty. Uses C<-s>.

=head2 owned

Corresponds to C<-o>.

=head2 r_readable

Corresponds to C<-R>.

=head2 r_writeable

=head2 r_writable

Corresponds to C<-W>.

=head2 rdev

See "stat tests".

=head2 readable

Corresponds to C<-r>.

=head2 setgid

Corresponds to C<-g>.

=head2 setuid

Corresponds to C<-u>.

=head2 size

See stat tests.

=head2 socket

Corresponds to C<-S>.

=head2 sticky

Corresponds to C<-k>.

=head2 symlink

Corresponds to C<-l>.

=head2 uid

See "stat tests".

=head2 tty

Corresponds to C<-t>.

=head2 writable()

Corresponds to C<-w>.

=head1 BUGS

The code relies on qr// compiled regexes, therefore this module
requires perl version 5.005_03 or newer.

Currently it isn't possible to remove a clause from a rule object.  If
this becomes a significant issue it will be addressed.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net> with input gained from this
use.perl discussion: http://use.perl.org/~richardc/journal/6467

Additional proofreading and input provided by Kake, Greg McCarroll,
and Andy Lester andy@petdance.com.

Ported to use L<File::Find::Object> as File::Find::Object::Rule by
Shlomi Fish.

=head1 COPYRIGHT

Copyright (C) 2002, 2003, 2004, 2006 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Object>, L<Text::Glob>, L<Number::Compare>, find(1)

If you want to know about the procedural interface, see
L<File::Find::Object::Rule::Procedural>, and if you have an idea for a neat
extension, see  L<File::Find::Object::Rule::Extending> .

L<Path::Class::Rule> ’s SEE ALSO contains a review of many directory traversal
modules on CPAN, including L<File::Find::Object::Rule> and L<File::Find::Rule>
(on which this module is based).

=head1 KNOWN BUGS

The tests don't run successfully when directly inside an old Subversion
checkout, due to the presence of C<.svn> directories. C<./Build disttest> or
C<./Build distruntest> run fine.

=cut

=begin Developers

Implementation notes:

[0] Currently we use an array of anonymous subs, and call those
repeatedly from match.  It'll probably be way more effecient to
instead eval-string compile a dedicated matching sub, and call that to
avoid the repeated sub dispatch.

[1] Though [0] isn't as true as it once was, I'm not sure that the
subs stack is exposed in quite the right way.  Maybe it'd be better as
a private global hash.  Something like $subs{$self} = []; and in
C<DESTROY>, delete $subs{$self}.

That'd make compiling subrules really much easier (no need to pass
@subs in for context), and things that work via a mix of callbacks and
code fragments are possible (you'd probably want this for the stat
tests).

Need to check this currently working version in before I play with
that though.

[*] There's probably a win to be made with the current model in making
stat calls use C<_>.  For

  find( file => size => "> 20M" => size => "< 400M" );

up to 3 stats will happen for each candidate.  Adding a priming _
would be a bit blind if the first operation was C< name => 'foo' >,
since that can be tested by a single regex.  Simply checking what the
next type of operation doesn't work since any arbritary exec sub may
or may not stat.  Potentially worse, they could stat something else
like so:

  # extract from the worlds stupidest make(1)
  find( exec => sub { my $f = $_; $f =~ s/\.c$/.o/ && !-e $f } );

Maybe the best way is to treat C<_> as invalid after calling an exec,
and doc that C<_> will only be meaningful after stat and -X tests if
they're wanted in exec blocks.

=end Developers

=cut
