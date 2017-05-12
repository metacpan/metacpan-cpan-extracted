package Inline::Mason::OO;

use strict;
our $VERSION = '0.02';

use AutoLoader;
use Inline::Mason::Base;
our @EXPORT = qw(AUTOLOAD);
our @ISA = qw(Inline::Mason::Base AutoLoader);


use Text::MicroMason qw(execute);
use Inline::Files::Virtual;

our @files_to_load;
sub to_load_files {
    push @files_to_load, @_;
}

sub import {
    shift;
    my $no_autoload;
    foreach my $arg (@_){
	$no_autoload = 1 if($arg eq 'no_autoload');
    }
    to_load_files((caller(0))[1]) unless $no_autoload;
}

sub new {
    my $pkg = shift;
    my @file = @_;
    my $self = bless {} => $pkg;
    foreach my $f (grep{$_} @files_to_load, (caller(0))[1], @file){
	$self->load_file($f);
    }
    $self;
}


sub load_mason {
    my $self = shift;
    my %arg = @_;
    my ($pkg) = (caller(0))[0];
    no strict;
    while(my($marker, $content) = each %arg){
	die err_taboo($marker) if $taboo_word{$marker};
	$self->{template}{$marker} = $content if $content;
    }
}

sub load_file {
    my $self = shift;
    my $filename = shift;

    my @virtual_filenames = vf_load($filename, $file_marker) or die;
    local $/;
    foreach my $vfile (@virtual_filenames){
	my $marker = vf_marker($vfile);
	$marker =~ s/\n+//so;
	$marker =~ s/^__(.+?)__/$1/so;
	die err_taboo($marker) if $taboo_word{$marker};
	vf_open(my $F, $vfile) or die "$! ==> $marker";
	my $content = <$F>;
	$self->load_mason($marker, $content) if $content;
	vf_close $F;
    }
}

sub generate {
    my $self = shift;
    my $name = shift;
    my %args = @_;
    execute($template->{(caller(0))[0]}{$name}, %args);
}

sub DESTROY {
    my $self = shift;
    undef $self;
}

sub AUTOLOAD{
    use vars '$AUTOLOAD';
    $AUTOLOAD =~ /.+::(.+)/o;
    my $self = shift;
    my $pkg = (caller(0))[0];
    if(defined $self->{template}{$1}){
	execute($self->{template}{$1}, @_);
    }
    else {
	die "${pkg}::$1 does not exist.\n";
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Inline::Mason::OO - Inline OO Mason

=head1 SYNOPSIS

=head3 MY::Mason file:

    package MY::Mason;
    use Inline::Mason::OO;  # __CARDINALS__ will automatically loaded.
    # or
    # use Inline::Mason::OO qw(no_autoload);
    # to escape from loading __CARDINALS__
    our @ISA = qw(Inline::Mason::OO);

    1;
    __END__

    __CARDINALS__
    % my @cardinals = qw(eins zwei drei);
    <% join q/ /, @cardinals %>


=head3 My perl script:

    use MY::Mason
    my $m = new MY::Mason ('t/external_mason');
    print $m->HELLO();
    print $m->NIFTY(lang => 'Perl');
    print $m->CARDINALS();



    __END__

    __HELLO__
    % my $noun = 'World';
    Hello <% $noun %>!
    How are ya?

=head3 t/external_mason

    __NIFTY__
    <% $ARGS{lang} %> is nifty!


=head1 DESCRIPTION

This module extends the power of L<Inline::Mason> to an OO level. You may use it to build a module specific for generating documents, like help documentation, etc.

=head2 ON IMPORTING

On importing the module, by default, the inline-mason will be loaded. However, you can still pass 'no_autoload' stating that you don't want the module to automatically load inline-mason scripts dwelling in the module file.

    use Inline::Mason::OO qw(no_autoload);

Besides, you can call 'to_load_files' in the parent module, and the files will be loaded every time when you instantiate a new object.

    package MY::Mason;
    use Inline::Mason::OO;
    our @ISA = qw(Inline::Mason::OO);
    Inline::Mason::OO::to_load_files(@files);

    1;
    __END__

And, of course, you can do this superfluous and redundant action.

    package MY::Mason;
    use Inline::Mason::OO qw(no_autoload);
    our @ISA = qw(Inline::Mason::OO);
    Inline::Mason::OO::to_load_files(__FILE__);

    1;
    __END__



=head2 METHODS

=head3 new

The constructor takes a list of file's names in which mason scripts reside and will load them to the instance. The file where the constructor is called is always loaded by default.

=head3 load_mason

Create mason scripts in place, and you can pass a list of pairs.


Load mason script in place:

    my $m = new MY::Mason;
    $m->load_mason
    (
     BEATLES
     =>
     'Nothing\'s gonna change my <% $ARGS{what} %>',
     # ... ... ...
     );

    print $m->BEATLES(what => 'world');

=head3 load_file

Load an external file manually and explicitly.

    my $m = new MY::Mason;
    $m->load_file('external_mason.txt');


=head1 SEE ALSO

L<Inline::Mason>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
