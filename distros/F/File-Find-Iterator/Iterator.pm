package File::Find::Iterator;


# Copyright (c) 2003 Robert Silve
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. 

require Exporter;
use Class::Iterator qw(igrep imap);
use Carp;
use IO::Dir;
use Storable;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter Class::Iterator);
@EXPORT = qw(imap igrep);

$VERSION = "0.4";

sub walktree {
    my ($opt, @TODO) = @_;
    my %opt = %$opt;

    return sub {

	if ($opt{statefile} && -e $opt{statefile} ) {
	    my $rTODO = retrieve($opt{statefile}) || 
		croak "Can't retrieve from $opt{statefile} : $!\n";
	    @TODO = @$rTODO;
	}
	
	return unless @TODO;
	my $item = pop @TODO;
	$item =~ s%/+$%%;
	if (-d  $item  ) {
	    my $d = IO::Dir->new($item);
	    while (defined($_ = $d->read)) { 
		next if ($_ eq '.' || $_ eq '..');
		push @TODO, "$item/$_";
	    }
	}

	if ($opt{order}) {
	    @TODO = sort {$opt{order}->($a,$b)} @TODO;
	}
	if ($opt{statefile}) {
	    store(\@TODO, $opt{statefile}) ||
		croak "Can't store to $opt{statefile} : $!\n";
	}
	
	return $item;
    }
}



sub create {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
    
    my $gen_code = sub {
	walktree({statefile => $args{statefile},
		  order => $args{order} } ,
		 @{$args{dir}}) 
	};
    
    my $self = $class->SUPER::new($gen_code);
    $self = igrep { $args{filter}->() } $self if $args{filter};
    $self = imap { $args{map}->() } $self if $args{map};
    map { $self->{$_} = $args{$_} } keys %args;
    return $self;
}



sub first {
    my $self = shift;
    my $gen_code = sub {
	walktree({statefile => $self->statefile,
		  order => $self->order } ,
		 @{$self->dir}) 
	};
    $self->generator($gen_code);
    $self->init;
    my $oo = igrep { $self->filter->() } $self if $self->filter;
    map { $self->{$_} = $oo->{$_} } keys %{$oo}; 
    my $oo2 = imap { $self->map->() } $self if $self->map;
    map { $self->{$_} = $oo2->{$_} } keys %{$oo2}; 
}


sub AUTOLOAD {
    my ($self) = @_;
    my ($pack, $meth) =($AUTOLOAD =~ /^(.*)::(.*)$/);
    return if $meth eq 'DESTROY';	
    my @auth = qw(dir filter map statefile order);
    my %auth = map { $_ => 1 } @auth;

    unless ($auth{$meth}) {
	croak "Unknow method $meth";
    }
    
    my $code = sub {
	my $self = shift;
	my $arg = shift;
	if ($arg) {
	    $self->{$meth} = $arg;
	} else {
	    return $self->{$meth};
	}
    };
    
    *$AUTOLOAD = $code;
    goto &$AUTOLOAD;
	    
}

1;


__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Find::File::Iterator - Iterator interface for search files

=head1 SYNOPSIS

  use File::Find::Iterator;
  my $find = File::Find::Iterator->create(dir => ["/home", "/var"],
                                          filter => \&isdir);
  sub isdir { -d }

  while (my $f = $find->next) { print "file : $f\n" }
  
  #reread with different filter 
  $find->filter(\&ishtml);
  $find->first;
  while (my $f = $find->next) { print "file : $f\n" }

  sub ishtml { /\.html?$/ }

  # using file for storing state
  $find->statefile($statefile);
  $find->first;
  # this time it could crash
  while (my $f = $find->next) 
  { print "file : $f\n" }

  # using imap and igrep
  use File::Find::Iterator qw(imap igrep);
  my $find = File::Find::Iterator->new(dir => ["/home", "/var"]);
  $find = imap { -M } igrep { -d } $find;

=head1 DESCRIPTION

Find::File::Iterator is an iterator object for searching through directory
trees. You can easily run filter on each file name. You can easily save the
search state when you want to stop the search and continue the same search 
later.

Find::File::Iterator inherited from L<Class::Iterator> so you can use the
imap and the igrep constructor.

=over 4

=item create(%opt)

This is the constructor. The C<%opt> accept the following key :

=over 4

=item dir C<< => \@dir >> 

which take a reference to a list of directory.

=item filter C<< => \&code >>

which take a code reference

=item statefile C<< => $file >>

which take a filename

=back

=item next

calling this method make one iteration. It return file name or 
C<undef> if there is no more work to do.

=item first

calling this method make an initialisation of the iterator.
You can use it for do a search again, but with some little 
change (directory root, statefile option, different filter).

=item dir([ \@dir ])

this method get or set the directory list for the search.

=item filter([ \&code ])

this method get or set the filter method use by C<next> method.

=item statefile([ $file ])

this method get or set the name of the file use for store state of the 
search (see L</"STORING STATE">).

=back



=head1 STORING STATE

If the option C<statefile> of the constructor or the C<statefile> field
of the object is set, the iterator use the L<Storable> module to record
is internal state after one iteration and to set is internal state before
a new iteration. With this mechanism you can continue your search after 
an error occurred.

=head1 SEE ALSO

L<Class::Iterator>

=head1 CREDITS

Marc Jason Dominius's YAPC::EU 2003 classes.

=head1 AUTHOR

Robert Silve <robert@silve.net>

=cut
