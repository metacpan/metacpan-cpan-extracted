package Language::Zcode::Translator::XML;

=head1 NAME

Language::Zcode::Translator::XML - Translate Z-code into XML

=head1 DESCRIPTION

This is an extremely simple proof of concept. It just parses the Z-file
and outputs it as an XML file. With some really fancy css work, I suspect you
could do some neat stuff, though.

=cut

@Language::Zcode::Translator::XML::ISA = qw(Language::Zcode::Translator::Generic);
my $indent = ""; # indent subs for readability
# store commands until done with a routine
my ($save_name, $save_locals, @command_xml) = ("",[]); 

sub new {
    my ($class, @arg) = @_;
    eval "use XML::Simple";
    die "Can't output XML without XML::Simple module\n$@\n" if $@;
    bless {}, $class;
}

sub program_start {
# Header for CSS: <?xml-stylesheet href="b2.css" type="text/css"?>
    my $top = <<'ENDTOP';
<?xml version="1.0" standalone="yes"?>
<?xml-stylesheet type="text/xsl" href="zcode.xsl"?>
<zfile>

ENDTOP
    my @xml_const = map { 
	{ constant_key => $_, value => $Language::Zcode::Util::Constants{$_} } 
    } keys %Language::Zcode::Util::Constants;
    my $xcref = {constants => [\@xml_const]};
    #$top .= XMLout(@xml_const, rootname => "constants", noattr => 1);
    $top .= XMLout($xcref, noattr => 1, keeproot => 1);
    return $top . "\n";
}

sub program_end { "</zfile>\n" }

sub routine_start {
    my ($self, $addr, @locals) = @_;
    @command_xml = (); # (re)start collecting commands
    ($save_addr, $save_locals) = ($addr, \@locals); # save for routine_end
    return "";
}

sub routine_end {
    my $self = shift;
    my $save_xml = XMLout( {
	    addr => $save_addr,  # addr of previous sub
	    name => "rtn$save_addr",  # name of previous sub
	    locv => $save_locals, # locals of previous sub
	    command => \@command_xml, # stored commands of previous sub
	}, 
	noattr => 1, rootname => "subroutine");
    return $save_xml . "\n";
}

# Translate Z op and args into XML
sub translate_command {
    my ($self, $href) = @_;
    my %parsed = %$href;
    my $opcode = $parsed{opcode} or return; # totally unknown opcode?
    my $command = "OOPS. No Command Here\n"; # command to return
    
#    Leave ^'s in print strings, since XML will ignore literal \n's
#    if (exists $parsed{print_string}) { $parsed{print_string} =~ s/\^/\n/g }

    # pack addresses
    foreach my $key (qw(packed_address_of_string routine)) {
        if (exists $parsed{$key}) {
            $parsed{$key} = $self->packed_address_str($parsed{$key}, $key);
        }
    }

    # Turn variable number of args (if any) into a Perl list
    # Btw, call_1n takes no args, so arg_list will be "" for call_1n, too
    $parsed{args} = exists $parsed{args}
        #?  join(", ", map {$self->make_var($_)} @{$parsed{"args"}})
        ?  join(", ", @{$parsed{"args"}})
        : "";

    push @command_xml, \%parsed;
    return "";
}

sub make_var {
    my ($self, $a, $is_lval) = @_;
    # XXX Help!
    return $a;
}

sub newlineify {
    my $s = pop;
    $s =~ s/\n/\\n/g;
    return $s;
}

sub write_memory {
    # XXX should really move hexification to Translator::Generic
    # change each byte to two hex digits
    my $l = @Language::Zcode::Util::Memory;
    my $hexed = "";
    for (my $c = 0; $c < $l; $c+=16) {
	# Add hex "line number" & \n's.
	my $len = $l - $c;
	$len = 16 if $len > 16;
	$hexed .= sprintf("%06x  " . " %02x" x $len . "\n",  $c,
	    @Language::Zcode::Util::Memory[$c .. $c + $len -1]);
    }
    my $str = <<"ENDUNPACK";

<memory>
<!--
# Addr    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f -->
$hexed
</memory>
ENDUNPACK
    return $str;
}

1;
