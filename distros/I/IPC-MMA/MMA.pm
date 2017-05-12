package IPC::MMA;

use strict;
use warnings;
use Carp;
require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);

# set the version for version checking
our $VERSION = 0.81;

# nothing is exported into callers namespace by default
our @EXPORT = qw( );

# exported by request
our %EXPORT_TAGS = (
basic => [qw(
    mm_maxsize         mm_create           mm_permission           mm_destroy
    mm_lock            mm_unlock           MM_LOCK_RD              MM_LOCK_RW
    mm_available       mm_error            mm_display_info         
    mm_alloc_size      mm_round_up )], # last 2 are ours
scalar => [qw(
    mm_make_scalar     mma_make_scalar     mm_free_scalar         mma_free_scalar
    mm_scalar_fetch    mma_scalar_fetch    mm_scalar_store        mma_scalar_store
    mm_scalar_get      mma_scalar_get      mm_scalar_set          mma_scalar_set )],
array => [qw(
    mm_make_array      mma_make_array      mm_array_status        mma_array_status
    mm_array_fetch     mma_array_fetch     mm_array_fetch_nowrap  mma_array_fetch_nowrap
    mm_array_store     mma_array_store     mm_array_store_nowrap  mma_array_store_nowrap
    mm_array_extend    mma_array_extend    mm_array_storesize     mma_array_storesize
    mm_array_exists    mma_array_exists    mm_array_exists_nowrap mma_array_exists_nowrap
    mm_array_splice    mma_array_splice    mm_array_splice_nowrap mma_array_splice_nowrap    
    mm_array_delete    mma_array_delete    mm_array_delete_nowrap mma_array_delete_nowrap
    mm_array_push      mma_array_push      mm_array_pop           mma_array_pop
    mm_array_shift     mma_array_shift     mm_array_unshift       mma_array_unshift
    mm_array_clear     mma_array_clear     mm_free_array          mma_free_array
    mm_array_fetchsize mma_array_fetchsize 
    MM_BOOL_ARRAY      MM_DOUBLE_ARRAY     MM_INT_ARRAY           MM_UINT_ARRAY
    MM_ARRAY           MM_FIXED_REC        MM_CSTRING )],
hash => [qw(
    mm_make_hash       mma_make_hash       mm_hash_fetch          mma_hash_fetch
    mm_hash_get        mma_hash_get        mm_hash_get_value      mma_hash_get_value
    mm_hash_get_entry  mma_hash_get_entry
    mm_hash_exists     mma_hash_exists     mm_hash_delete         mma_hash_delete
    mm_hash_store      mma_hash_store      mm_hash_insert         mma_hash_insert
    mm_hash_first_key  mma_hash_first_key  mm_hash_next_key       mma_hash_next_key
    mm_hash_scalar     mma_hash_scalar     mm_hash_clear          mma_hash_clear
    mm_free_hash       mma_free_hash       MM_MUST_CREATE         MM_NO_CREATE
    MM_NO_OVERWRITE )],
btree => [qw(
    mm_make_btree_table      mma_make_btree_table     
    mm_btree_table_insert    mma_btree_table_insert
    mm_btree_table_get       mma_btree_table_get      
    mm_btree_table_exists    mma_btree_table_exists
    mm_btree_table_delete    mma_btree_table_delete   
    mm_btree_table_first_key mma_btree_table_first_key
    mm_btree_table_next_key  mma_btree_table_next_key 
    mm_clear_btree_table     mma_clear_btree_table
    mm_free_btree_table      mma_free_btree_table 
    MM_MUST_CREATE           MM_NO_CREATE               MM_NO_OVERWRITE)] );

# make the ":all" class as the union of the others, eliminating duplicates)
{   my %seen;
    push @{$EXPORT_TAGS{all}}, 
        grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} for (keys %EXPORT_TAGS);
}
# callers can import any of those
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

# AUTOLOAD is used to
#  1) 'autoload' constants from the constant() function in MMA.xs
# If the name is not a constant then it's parsed for
#  2) a tie package-name::function-name, which if matched is executed

our $AUTOLOAD;  # implicit argument of AUTOLOAD

sub AUTOLOAD {

    # make the base name (without the "package::")
    (my $constname = $AUTOLOAD) =~ s/.*:://;
    # call the constant lookup routine in MMA.xs
    my $val = constant($constname, 0);
    if ($!) {

        # the name in $AUTOLOAD is not a constant defined by IPC::MMA
                     # sah = scalar/array/hash
        if (my ($mmx, $sah, $function) =
            $AUTOLOAD =~ /^IPC::(MMA?)::(Scalar|Array|Hash|BTree)::([A-Z]+)$/) {

            if (($sah = lc $sah) eq 'btree') {$sah = 'hash'}
 
            if ($function eq uc("TIE$sah")) {
                my $self = shift;
                my $base_sah = shift; # sah = scalar/array/hash
                $val = '';
                if (!$base_sah || ($val = ref($base_sah)) ne "mm_${sah}Ptr") {
                    croak "3rd operand of tie should be the return value from "
                        . " mm_make_$sah: ref was '$val'";
                }
                return bless \$base_sah, $self;

                                   # Scalar or Array or Hash
            } elsif ($function eq 'FETCH'
                  || $function eq 'STORE'
                  || $sah ne 'scalar' # Array or Hash
                  && $function =~ /^(DELETE|EXISTS|CLEAR)$/
                  || $sah eq 'array'
                  && $function =~ /^(FETCHSIZE|SHIFT|POP|PUSH|UNSHIFT|SPLICE|EXTEND|STORESIZE)$/
                  || $sah eq 'hash'
                  && $function =~ /^(NEXTKEY|SCALAR|FIRSTKEY)$/) {

                $function =~ s/KEY$/_KEY/;

                if ($sah eq 'array'                             # nowrap
                 && $function =~ /^(FETCH$|STORE$|EXI|D|SP)/) { # nowrap
                    $function .= '_nowrap';                     # nowrap
                }
                my $subname = lc($mmx) . "_${sah}_" . lc($function);
                ####temp
                # carp "$subname was called";

                no strict 'refs';
                
                # define the symbol so AUTOLOAD won't be called again for this name
                *$AUTOLOAD = sub {
                    # dereference the base scalar/array/hash
                    my $base_sah_ref = shift;
                    unshift @_, $$base_sah_ref;
                    # go to the constructed sub name in MMA.xs
                    goto &$subname;
                };
                # having defined the symbol, execute the sub above 
                #   and then the one in MMA.xs
                goto &$AUTOLOAD;

            } elsif ($function eq 'UNTIE'
                  || $function eq 'DESTROY') {
                return;  # do nothing
        }   }
        croak "$AUTOLOAD is not a defined constant or subroutine for IPC::MMA";
    }
    # the name in $AUTOLOAD is a constant defined by IPC::MMA: define it for perl
    no strict 'refs';
    # define the symbol so AUTOLOAD won't be called again for this name
    *$AUTOLOAD = sub{$val};
    # in the general case the following line should be 'goto &$AUTOLOAD;'
    return $val;
}
bootstrap IPC::MMA $VERSION;
1;

# these exist only to serve as 'tie' methods: they cannot be use'd
# (this is a bit repetitive)
package IPC::MM::Scalar;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
1;
package IPC::MMA::Scalar;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
1;
package IPC::MM::Array;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
1;
package IPC::MMA::Array;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
1;
package IPC::MM::Hash;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
# have to declare SCALAR so perl will call our SCALAR -> mm_hash_scalar
sub SCALAR;
1;
package IPC::MMA::Hash;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
sub SCALAR;
1;
package IPC::MM::BTree;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
sub SCALAR;
1;
package IPC::MMA::BTree;
use strict;
use warnings;
our @ISA = qw(IPC::MMA);
sub SCALAR;
1;
