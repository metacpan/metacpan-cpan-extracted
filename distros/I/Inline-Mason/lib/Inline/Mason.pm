package Inline::Mason;

use strict;

our $VERSION = '0.07';

use Inline::Mason::Base;
use AutoLoader;
our @EXPORT = qw(AUTOLOAD);
our @ISA = qw(Inline::Mason::Base AutoLoader);

use Text::MicroMason qw(
			execute
			compile
			execute_file
			safe_execute
			try_execute
			);
use Inline::Files::Virtual;


sub import {
    shift;
    my @ext_files;
    my ($pkg, $script_name) = (caller(0))[0,1];

    foreach my $t (@_){	
	$as_subs->{$pkg} = 1 if $t eq 'as_subs';
	$passive->{$pkg} = 1 if $t eq 'passive';
	$use_oo->{$pkg} = 1  if $t eq 'OO';
	@ext_files = @$t if ref($t) eq 'ARRAY';
    }
    return 1 if $passive->{$pkg};

    foreach my $real_file ($script_name, @ext_files){
	load_file($real_file, $pkg);
    }
}

sub load_mason {
    my %arg = @_;
    my ($pkg) = (caller(0))[0];
    no strict;
    while(my($marker, $content) = each %arg){
	die err_taboo($marker) if $taboo_word{$marker};
	unless( defined $template->{$pkg}{$marker} ){
	    $template->{$pkg}{$marker} = $content;
	}
	*{"${pkg}::$marker"} = \&{"Inline::Mason::$marker"} if $as_subs->{$pkg};
    }
}

sub load_file {
    my $filename = shift;
    my $pkg = shift || (caller(0))[0];

    my @virtual_filenames = vf_load($filename, $file_marker);
    local $/;
    foreach my $vfile (@virtual_filenames){
	my $marker = vf_marker($vfile);
	$marker =~ s/\n+//so;
	$marker =~ s/^__(.+?)__/$1/so;
	die err_taboo($marker) if $taboo_word{$marker};
	vf_open(my $F, $vfile) or die "$! ==> $marker";
	my $content = <$F>;
	next unless $content;
	$template->{$pkg}{$marker} = $content;
	no strict;
	*{"${pkg}::$marker"} = \&{"Inline::Mason::$marker"} if $as_subs->{$pkg};
	vf_close $F;
    }
}

sub generate {
    my $name = shift;
    my %args = @_;
    execute($template->{(caller(0))[0]}{$name}, %args);
}


sub AUTOLOAD{
    use vars '$AUTOLOAD';
    $AUTOLOAD =~ /.+::(.+)/o;
    my $pkg = (caller(0))[0];
    if(defined $template->{$pkg}{$1}){
	execute($template->{$pkg}{$1}, @_);
    }
    else {
	die "${pkg}::$1 does not exist.\n";
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Inline::Mason - Inline Mason Script

=head1 SYNOPSIS

    package MY::Mason;
    use Inline::Mason 'as_subs';
    our @ISA = qw(Inline::Mason);

    print Inline::Mason::generate('HELLO');
    print Inline::Mason::HELLO();
    print HELLO();
    print NIFTY(lang => 'Perl');



    __END__

    __HELLO__
    % my $noun = 'World';
    Hello <% $noun %>!
    How are ya?

    __NIFTY__
    <% $ARGS{lang} %> is nifty!


=head1 DESCRIPTION

This module enables you to embed mason scripts in your perl code. Using it is simple, much is shown in the above.

=head2 OPTIONS

=head3 as_subs

Invoking Inline::Mason with it may let you treat virtual files as subroutines and call them directly.

=head3 passive

If it is passed, the module will not spontaneously load mason scripts until you explicitly load them.

=head2 FUNCTIONS

=head3 load_mason

Create mason scripts in place, and you can pass a list of pairs.


    Inline::Mason::load_mason
    (
     BEATLES
     =>
     'Nothing\'s gonna change my <% $ARGS{what} %>',
     # ... ... ...
     );

    print BEATLES(what => 'world');

=head3 load_file

Load an external file manually and explicitly, and the scripts will belong to the caller's package. This is a safer and more robust way when L<Inline::Mason> is used across several files and packages.


    use Inline::Mason qw(passive as_subs);
    Inline::Mason::load_file('external_mason.txt');



=head1 EXTERNAL MASON

As is said in the above, I<load_file> serves the purpose. Also, you can specify the files wherein mason scripts reside when you first use the module. All you need to do is pass their names when you use the module, and then L<Inline::Mason> will actively process them.

  use Inline::Mason 'as_subs', [qw(external_mason.txt)];

When duplicated mason script's marker appears, new one overrides the old one.


=head1 PER-PACKAGE MASON

Inline mason scripts are specific to packages. It means if you load virtual files within two different package context, files with the same marker will be viewed as different entities.

An small example is illustrated below.

File A.pm

  package A;
  use Inline::Mason qw(as_subs);
  1;
  __END__
  __Mason__
  Hello, World.


File B.pm

  package B;
  use Inline::Mason qw(as_subs);
  require 'A.pm';
  package A;
  print Mason();        # Hello, World.
  package B;
  print Mason();        # Hola, el mundo.
  1;
  __END__
  __Mason__
  Hola, el mundo.


=head1 Text::MicroMason methods

You can also call methods provided by L<Text::MicroMason> using Inline::Mason.

  Inline::Mason::execute( $hello );
  Inline::Mason::safe_execute( $hello );
  Inline::Mason::try_execute( $hello );

  $n = Inline::Mason::compile( $nifty );
  $n->(lang => "Perl");

  Inline::Mason::execute_file( 't/external_mason', lang => "Perl" );


=head1 SEE ALSO

See L<Inline::Mason::OO> for an object-oriented and extended style of L<Inline::Mason>

This module uses L<Text::MicroMason> as its backend instead of L<HTML::Mason>, because it is much lighter and more accessible for this purpose. Please go to L<Text::MicroMason> for details and its limitations.

=head1 CAVEAT

This module is not mature yet, and everything is subject to changes. Use it with your own caution.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
