package HackaMol::Roles::SelectionRole;
$HackaMol::Roles::SelectionRole::VERSION = '0.053';
#ABSTRACT: Atom selections in molecules
use Moose::Role;
use HackaMol::AtomGroup;
use Carp;


my %common_selection = (
    'sidechain'  => '$_->record_name eq "ATOM" and not $_->name =~ /^(N|CA|C|O|OXT)$/',  
    'backbone'   => '$_->record_name eq "ATOM" and     $_->name =~ /^(N|CA|C|O)$/', # backbone restricted to ATOM to avoid HETATM weirdness, e.g. het cys in 1v1q
    'water'      => '$_->resname =~ m/HOH|TIP|H2O/ and $_->record_name eq "HETATM"',
    'protein'    => '$_->record_name eq "ATOM"',
    'ligands'    => '($_->resname !~ m/HOH|TIP|H2O/ ) and $_->record_name eq "HETATM"',
    'metals'     => '$_->symbol =~ m/^(Li|Be|Na|Mg|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|Cs|Ba|La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg)$/', 
);

has 'selection' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    default => sub { {} },
    handles => {
        get_selection    => 'get',
        set_selection    => 'set',
        has_selection   => 'count',
        keys_selection   => 'keys',
        delete_selection => 'delete',
        has_selection    => 'exists',
    },
);


has 'selections_cr' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    lazy    => 1,
    handles => {
        get_selection_cr    => 'get',
        set_selection_cr    => 'set',
        has_selections_cr   => 'count',
        keys_selection_cr   => 'keys',
        delete_selection_cr => 'delete',
        has_selection_cr    => 'exists',
    },
);

sub select_group {

    my $self      = shift;
    my $selection = shift;
    my $method;

    if ($self->has_selection_cr($selection)){ #attr takes priority so user can change
        $method = $self->get_selection_cr($selection);
    }
    elsif ( exists( $common_selection{$selection} ) ) {
        $method = eval("sub{ grep{ $common_selection{$selection} } \@_ }");
    }
    else {
        $method = _regex_method($selection);
    }

    #grep { &{ sub{ $_%2 } }($_)} 1..10

    my $group =
      HackaMol::AtomGroup->new( atoms => [ &{$method}( $self->all_atoms ) ], );

    return ($group);

}

# $mol->select_group('(chain A .or. (resname TYR .and. chain B)) .and. occ .within. 1')
# becomes grep{($_->chain eq A or ($_->resname eq TYR and $_->chain eq 'B')) and $_->occ <= 1.0}

sub _regex_method {
    my $str = shift;
    
    # allow and or  .and.  .or. ...  does this cause other problems with names?
    $str =~ s/\sand\s/ \.and\. /g;
    $str =~ s/\sor\s/ \.or\. /g;
    $str =~ s/\snot\s/ \.not\. /g;

    #print "$str not implemented yet"; return(sub{0});
    #my @parenth = $str =~ /(\(([^()]|(?R))*\))/g

    # ranges resid 1+3-10+20 -> resid =~ /^(1|3|4|5|6|7|8|9|10|20)$/
    my @ranges = $str =~ /(\w+\s+(?:\w+|\d+)(?:\+|\-)[^\s]+)/g;
    foreach my $range (@ranges){
      my ($attr,$sel) = split(/\s+/, $range);
      #$range =~ s/\+/\\+/g;
      #$range =~ s/\-/\\-/g;
      my $gsel = join '|',map{/(.+)-(.+)/ ? ($1 .. $2) : $_ } split('\+', $sel );
      $str =~ s/\Q$range\E/\$\_->$attr =~ \/^($gsel)\$\//g;
    }

    $str =~ s/(\w+)\s+(\d*[A-Za-z]+\d*)/\$\_->$1 eq \'$2\'/g;  # resnames must have at least 1 letter
    $str =~ s/(\w+)\s+(-?\d+)/\$\_->$1 eq $2/g;
    $str =~ s/(\w+)\s+\.within\.\s+(\d+)/\$\_->$1 <= $2/g;
    $str =~ s/(\w+)\s+\.beyond\.\s+(\d+)/\$\_->$1 >= $2/g;
    $str =~ s/$_/\($common_selection{$_}\)/g foreach keys %common_selection;
    $str =~ s/\.and\./and/g;
    $str =~ s/\.or\./or/g;
    $str =~ s/\.not\./not/g;

    return ( eval("sub{ grep{ $str } \@_ }") );
}



no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::SelectionRole - Atom selections in molecules

=head1 VERSION

version 0.053

=head1 DESCRIPTION

The goal of HackaMol::Roles::SelectionRole is to simplify atom selections.  This role is not loaded with the core; it 
must be applied as done in the synopsis.  The method commonly used is select_group, which uses regular expressions to convert 
a string argument to construct a method for filtering; a HackaMol::AtomGroup is returned. The select_group method operates 
on atoms contained within the object to which the role is applied (i.e. $self->all_atoms).  The role is envisioned for 
instances of the HackaMol::Molecule class.

=head2 Common Selections: backbone, sidechains, protein, etc.

Some common selections are included for convenience:  backbone, sidechains, protein, water, ligands, and metals.  

    my $bb = $mol->select_group('backbone'); 

=head2 Novel selections using strings: e.g. 'chain E', 'Z 8', 'chain E .and. Z 6'

Strings are used for novel selections, the simplest selection being the pair of one attribute with one value separated by a space. 
For example, "chain E" will split the string and return all those that match (atom->chain eq 'E').  

      my $enzyme = $mol->select_group('chain E');

This will work for any attribute (e.g. atom->Z == 8). This approach requires less perl know-how than the equivalent, 

      my @enzyme_atoms = grep{$_->chain eq 'E'} $mol->all_atoms;
      my $enzyme = HackaMol::AtomGroup->new(atoms=>[@enzyme_atoms]); 

More complex selections are also straightforward using the following operators:

      .or.         matches if an atom satisfies either selection (separated by .or.)
      .and.        matches if an atom satisfies both selections (separated by .and.)             
      .within.     less than or equal to for numeric attributes
      .beyond.     greater than or equal to for numeric attributes
      .not.        everything but

More, such as .around. will be added as needs arise. Let's take a couple of examples. 

1. To select all the tyrosines from chain E,

      my $TYR_E = $mol->select_group('chain E .and. resname TYR');

2. To choose both chain E and chain I,

      my $two_chains = $mol->select_group('chain E .or. chain I');

Parenthesis are also supported to allow selection precedence.  

3. To select all the tyrosines from chain E along with all the tyrosines from chain I,

      my $TYR_EI = $mol->select_group('(resname TYR .and. chain E) .or. (resname TYR .and. chain I)');

4. To select all atoms with occupancies between 0.5 and 0.95,

      my $occs = $mol->select_group('(occ .within. 0.95) .and. (occ .beyond. 0.5)');

The common selections (protein, water, backbone, sidechains) can also be used in the selections.  For example, select 
chain I but not the chain I water molecules (sometimes the water molecules get the chain id),

      my $chain_I =  $mol->select_group('chain I .and. .not. water');

=head2 Extreme selections using code references. 

The role also provides the an attribute with hash traits that can be used to create, insanely flexible, selections using code references. 
As long as the code reference returns a list of atoms, you can do whatever you want.  For example, let's define a sidechains selection; the 
key will be a simple string ("sidechains") and the value will be an anonymous subroutine.  
For example,

      $mol->set_selection_cr("my_sidechains" => sub {grep { $_->record_name eq 'ATOM' and not 
                                                     ( $_->name eq 'N' or $_->name eq 'CA'
                                                       or $_->name eq 'C' or $_->name eq 'Flowers and sausages')
                                                    } @_ }
      );

Now $mol->select_group('my_sidechains') will return a group corresponding to the selection defined above.  If you were to rename 
"my_sidechains" to "sidechains", your "sidechains" would be loaded in place of the common selection "sidechains" because of the priority
described below in the select_group method.  

=head1 METHODS

=head2 set_selections_cr

two arguments: a string and a coderef

=head2 select_group

takes one argument (string) and returns a HackaMol::AtomGroup object containing the selected atoms. Priority: the select_group method looks at 
selections_cr first, then the common selections, and finally, if there were no known selections, it passes the argument to be processed
using regular expressions.

=head1 ATTRIBUTES

=head2 selections_cr

isa HashRef[CodeRef] that is lazy with public Hash traits.  This attribute allows the user to use code references in the atom selections.
The list of atoms, contained in the role consuming object, will be passed to the code reference, and a list of atoms is the expected output
of the code reference, e.g.

    @new_atoms = &{$code_ref}(@atoms);

=head1 SYNOPSIS 

       # load 2SIC from the the RCSB.org and pull out two groups: the enzyme (chain E) and  the inhibitor (chain I) 

       use HackaMol;
       use Moose::Util qw( ensure_all_roles ); #  to apply the role to the molecule object

       my $mol = HackaMol->new->pdbid_mol("2sic"); #returns HackaMol::Molecule

       ensure_all_roles($mol, 'HackaMol::Roles::SelectionRole') # now $mol has the select_group method;

       my $enzyme = $mol->select_group("chain E");
       my $inhib  = $mol->select_group("chain I");

=head1 WARNING 

This is still under active development and may change or just not work.  I still need to add warnings to help with bad 
selections.  Let me know if you have problems or suggestions!

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
