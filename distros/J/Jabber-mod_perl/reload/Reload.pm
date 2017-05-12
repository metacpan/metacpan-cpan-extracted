package Jabber::Reload;
use strict;
use Cwd qw(abs_path);
use vars qw/$DEBUG $VERSION/;
$DEBUG = 1;

$VERSION='0.01';

=pod

=head1 NAME

Jabber::Reload - reload modules 

=head1 DESCRIPTION 

Reload is a helper module to reload modules that have changed during run time.

it is a bit of a copy of Apache::Reload, but not nearly as sophisticated,
it just check the time stamp on the file of a module that is registerd,
whacks the INC entry for it and then reloads over the top.

=head1 EXAMPLES

in the main of your program:

 use Jabber::Reload;

 Jabber::Reload::register(q|Some::Module|);

.... later during the loop

 if ( Jabber::Reload::haveModule(q|Some::Module|) ){
    Jabber::Reload::reload(q|Some::Module|);
 } else {
    Jabber::Reload::loadModule(q|Some::Module|);
 }

also - to ensure that modules loaded and registered 
by Reload are properly available in the current scope,
when using JabberReload::loadModule(), you must put the load in 
a BEGIN {} block like so:

 use Reload;
 BEGIN { Jabber::Reload::loadModule("TTest"); };

so that you can still address methods like this:
 TTest::handler;

as opposed to having to do this:
 TTest->handler;


=head1 AUTHOR

Piers Harding - after a lot of plagarism


=cut


my $modules = {};
my $files = {};


sub register {

my $mod = shift;
  $modules->{$mod} = get_time($mod);
 debug("starting modification time for $mod: ".localtime($modules->{$mod}));

}


sub haveModule{

  my $mod = shift;
    return exists $modules->{$mod} ? 1 : undef;

}


sub loadModule{

  my $mod = shift;
  return unless $mod;
  unless ( exists $modules->{$mod} ){
    unless ( get_path( $mod ) ){
      debug( "Cant locate: $mod ");
      return undef;
    };
    debug( "Loading Module : $mod" );
    eval "use $mod;";
    debug("EVAL ERR: $@ ") if $@;
    register( $mod );
  }

}


sub get_time {

  my $mod = shift;
  my $file = get_path( $mod );
  return undef unless $file;
  return (stat($file) )[9];

}


sub get_path {

  my $mod = shift;

  if ( exists $files->{$mod} ){
    return $files->{$mod};
  } else {
    my $pkg = $mod;
    $pkg =~ s/::/\//g;
    $pkg .= '.pm';
    if ( -f $pkg ){
      $files->{$mod} = $pkg;
      return $pkg;
    } else {
      my @incy = ( @INC );
      foreach ( @incy ){
        if ( -f $_.'/'.$mod.'.pm' ){
          $files->{$mod} = abs_path($_).'/'.$mod.'.pm';
  	  return $files->{$mod};
        }
      }
      return undef;
    }
  }

}

    
sub packageInINC { 
  
  my $mod = shift;
  return undef unless $mod;
  #debug( " \%INC KEYS -  \n".join('',map {  "key: $_ \n" } keys %INC) );
  my $file = get_path($mod);
  return undef unless $file;

  my $pkg = $mod;
  $pkg =~ s/::/\//g;
  $pkg .= '.pm';
  debug("package name: $pkg - file: $file");
  if ( exists $INC{$pkg} ){
    return $pkg;
  }
  return undef;

}


sub reload {

  my $mod = shift;
  #debug("modules is: $mod\n");
  return unless $mod;
  my $mtime = get_time($mod);
  #debug("modification time for $mod is: $mtime\n");
  return undef unless $mtime;
  #debug("$mod comparing: $mtime $modules->{$mod} \n");
  if ( $mtime > $modules->{$mod} ){
    debug("$mod is changed: ".localtime($mtime));
    $modules->{$mod} = $mtime;
    my $file = packageInINC( $mod );
    unless ( $file ){
       debug("Package: $file ($mod) not available in \%INC to reload");
    } else {
      delete $INC{$file} if exists $INC{$file};
#      no strict "refs";
#      undef %{"$mod"};
      delete_package($mod);
      require "$file";
      #eval "use $mod;";
      debug("EVAL ERR: $@ ") if $@;
      debug("Module: $mod reloaded");
      return 1;
    }
  }
  return undef;

}


# cribed from package Symbol
sub delete_package ($) {

    my $mod = shift;
    my $pkg = $mod;

    # expand to full symbol table name if needed
    $pkg .= '::'            unless  $pkg =~ /::$/;

    no strict "refs";
    my $symtab = *{$pkg}{HASH};
    return unless defined $symtab;

    # free all the symbols in the package
    foreach my $name (keys %$symtab) {
      debug("undef: $pkg$name");
      undef %{$pkg . $name};
    }

    # delete the symbol table
    undef %{"$mod"};

}


sub debug {

  return unless $DEBUG;
  print  STDERR scalar localtime().": ", @_, "\n";

}


1;
