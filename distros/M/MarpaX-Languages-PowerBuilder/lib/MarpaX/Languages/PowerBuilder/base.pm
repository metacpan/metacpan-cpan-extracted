package MarpaX::Languages::PowerBuilder::base;
use strict;
use warnings;
use File::BOM qw(open_bom);
use Encode qw(decode);
use File::Basename qw(dirname basename);
use Marpa::R2;
use Data::Dumper;

our $AUTO_DECODE = 1;	#used to auto decode input passed to the parse method

sub slurp{
	my $input = shift;
	local $/;
	open my $IN, '<:via(File::BOM)', $input;
	my $data = <$IN>;
	close $IN;
	$data;
}

sub new{
	my $class = shift;
	
	my $self = bless {}, $class;
		
	unless($self->can('grammar')){
		my $pkg  = ref $self;
		my $grammar = do{
			my $path = dirname(__FILE__);
			my $file = lc $pkg;
			$file =~ s/.*:://g;
			my $dsl = slurp( "$path/$file.marpa");
			Marpa::R2::Scanless::G->new( { source => \$dsl } );
		};
		#inject grammar method
		{
			no strict 'refs';
			*{$pkg.'::grammar'} = sub { $grammar };
		}
	}

	return $self;
}

sub parse{
	my $self = shift;
	die "forget to call new() ?" unless ref($self) && $self->can('grammar');
    my $input = shift;
    my $opts  = shift;
    #3 ways to pass inputs: glob, file-name, full-string
    if(ref $input eq 'GLOB'){
		$input = File::BOM::decode_from_bom( do{ local $/=undef; <$input> } );
    }
    elsif($input!~/\n/ && -f $input){
        $input = slurp $input;
    }
	
	if($AUTO_DECODE and $input=~/^\s*HA\$/i){
		$input = $self->hexascii_decode( $input );
	}
    	
    my $recce = Marpa::R2::Scanless::R->new({ 
            grammar => $self->grammar(), 
            semantics_package => ref($self)
        } );
    my $parsed = bless { recce => $recce, input => \$input, opts => $opts }, ref($self);
    eval{ $recce->read( \$input ) };
    $parsed->{error} = $@;
    return $parsed;
}

sub value{
	my $self = shift;
	unless(exists $self->{__value__}){
		$self->{__value__} = ${ $self->{recce}->value // \{} };
	}
	return $self->{__value__};
}

sub hadecode_hexseq{
    my $codes = shift;
	
    return decode('utf16le', pack 'H*', $codes);
}

sub hexascii_decode{
	my $self = shift;
	my $str = shift;
	
	$str =~ s/\$\$HEX\d+\$\$([a-fA-F0-9]+)\$\$ENDHEX\$\$/hadecode_hexseq($1)/ge;
	
	return $str;
}

1;