package Locale::Maketext::Pseudo;

use warnings;
use strict;

$Locale::Maketext::Pseudo::VERSION = '0.6';
require Exporter;
@Locale::Maketext::Pseudo::ISA = qw(Exporter);
@Locale::Maketext::Pseudo::EXPORT_OK = qw(env_maketext env_print env_fetch env_say env_get);

sub new {
    my($class, $args_ref) = @_;
    my $self = bless {}, $class;
    $ENV{'maketext_obj'} = $self if !$args_ref->{'skip_env'};
    return $self;
}

sub env_maketext {
    my ($string, @args) = @_;
    
    my $needs_elp = 1;
    if( exists $ENV{'maketext_obj'} ) {
        if( $ENV{'maketext_obj'} ) {
            if( $ENV{'maketext_obj'}->can('maketext') ) {
                $string = $ENV{'maketext_obj'}->maketext( $string, @args );
                $needs_elp = 0;
            }
        }
    }    
    
    if( $needs_elp ) {
        require Local::Maketext::Pseudo;
        Local::Maketext::Pseudo->new({ 
            'skip_env' => $ENV{'maketext_obj_skip_env'} 
        })->maketext( $string, @args );
    }
    
    return $string;
}

sub env_print {
    print env_maketext(@_);
}       

sub env_fetch { 
    return env_maketext(@_); 
}               
                    
sub env_say {           
    my $text = env_maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/; # otherwise assume they are not stupid
    print $text . $/ if $text;
}
    
sub env_get {
    my $text = env_maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/; # otherwise assume they are not stupid
    return $text . $/ if $text;
    return;             
}

sub maketext {
    my ($fake, $string, @args) = @_;

    for my $idx ( 1 .. scalar(@args)) {
        $string =~ s{ \[ [_]( [-]?$idx ) \] }{$args[ substr($1, 0, 1) eq '-' ? $1 : ($1 - 1) ]}xmsg;
    }

    return $string;
}

sub print {
    print shift->maketext(@_);
}       

sub fetch { 
    return shift->maketext(@_); 
}               
                    
sub say {           
    my $text = shift->maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/; # otherwise assume they are not stupid
    print $text . $/ if $text;
}
    
sub get {
    my $text = shift->maketext(@_);
    local $/ = !defined $/ || !$/ ? "\n" : $/; # otherwise assume they are not stupid
    return $text . $/ if $text;
    return;             
}

1; 

__END__

=head1 NAME

Locale::Maketext::Pseudo - give localized code a pseudo language obj if a real one does not exist.


=head1 VERSION

This document describes Locale::Maketext::Pseudo version 0.6


=head1 SYNOPSIS

    use Locale::Maketext::Pseudo;

    # localized Class::Std based object

    my %lang;
    
    sub BUILD {
        my ($self, $ident, $arg_ref) = @_;
        $lang{ $ident } = ref $arg_ref->{'lang_obj'} && $arg_ref->{'lang_obj'}->can('maketext') 
            ? $arg_ref->{'lang_obj'} : Locale::Maketext::Pseudo->new();
            ...
    }

Or in your main app so you can get on with writing it and have $lang available and functioning

   # TODO: setup Locale::Maketext::Utils based Lexicon and make $lang out of it but for now:
   my $lang = Locale::Maketext::Pseudo->new(); 


=head1 DESCRIPTION

Localized software is more useable by more people. You should localize your code. L<Locale::Maketext> has the easiest and best localization framework available IMHO, L<Local::Maketext::Utils> adds more useablility utility methods (for example, it adds say(), get(), print(), and fetch() to name just a few) and should be used in software of any size.

In a perfect world your main program would make a language object and pass it as part of an object constructor so that output the module might have is localized too.

What is your excellently localized module to do if no valid langauge object is passed? Or what can you do while you're setting up your Lexicon and what not?

You fallback to a Pseudo object so that the calls to maketext() (or say(), get(), print(), or fetch() if you'll be using a L<Locale::Maketext::Utils> obj) can be used and still get interpolated properly.


=head1 INTERFACE 

=head2 FUNCTIONS

All are exportable, each takes the same args as the method of the same name (sans 'env_') 
and each uses $ENV{'maketext_obj'} if valid or it uses a L<Local::Maketext::Pseudo> object.

=over 4

=item env_maketext()

This will use $ENV{'maketext_obj'} if it can maketext, otherwise it uses the Pseudo method.

This is useful for languagifying, say, a module's carp()'ed errors without the module needing to know anythgin about the callers' langauge situation.

    local $ENV{'maketext_obj'} = MyLocale::Maketext::Utils->get_handle(@whatever) || '';
    use Locale::Maketext::Pseudo qw(env_maketext);
    
    my $obj = Fiddle->new({'lang_obj' => $ENV{'maketext_obj'} }); # now object uses same thing as function, see "OBJECT ORIENTED" below...  
    carp env_maketext('....', @whatever) if !$whatever;

=item env_fetch()

=item env_print()

=item env_get()

=item env_say()

=back


=head2 OBJECT ORIENTED

=over

=item new()

Take no arguments, just returns an object with access to the methods below.

The "Pseudo" idea is from the fact that the arguments are the same as the "pseudo"-ified method, 
the return value is the same as "pseudo"-ified method but no actual Lexicon magic is done. (IE it acts as a funtioning pseudo placeholder for a real language object.)


=item maketext()

Pseudo L<Locale::Maketext>'s maketext()

=item say()

Pseudo L<Locale::Maketext::Utils>'s say()

=item get()

Pseudo L<Locale::Maketext::Utils>'s get()

=item print()

Pseudo L<Locale::Maketext::Utils>'s print()

=item fetch()

Pseudo L<Locale::Maketext::Utils>'s fetch()

=back

=head1 DIAGNOSTICS

Throws no warnings or exceptions of its own.


=head1 CONFIGURATION AND ENVIRONMENT

Locale::Maketext::Pseudo requires no configuration files and the foloowing environment variables:

$ENV{'maketext_obj'} gets set to the language object on initialization ( for functions to use, see "FUNCTIONS" above ) unless the 'skip_env' key is tru in new()'s hashref argument.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.

Special bracket notation for methods like '[quant,_1,file,files,No files] matched your query.' are simply left as is.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-locale-maketext-pseudo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
