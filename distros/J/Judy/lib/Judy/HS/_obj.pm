package Judy::HS;

# use strict;
# use warnings;
# 
# sub first_key { 0 }
# 
# sub get {
#     my $ptr = $_[0]->ptr;
#     return Judy::HS::Test( $ptr, $_[1] );
# }
# 
# sub set {
#     my $optr = my $ptr = $_[0]->ptr;
# 
#     if ( $_[2] ) {
#         Judy::HS::Set( $ptr, $_[1] );
#     }
#     else {
#         Judy::HS::Unset( $ptr, $_[1] );
#     }
#     if ( $optr != $ptr ) {
#         $_[0]->setptr( $ptr );
#     }
# 
#     return !! $_[2] ;
# }
# 
# sub delete {
#     my $optr = my $ptr = $_[0]->ptr;
#     my $oldval = Judy::HS::Unset( $ptr, $_[1] );
#     if ( $optr != $ptr ) {
#         $_[0]->setptr( $ptr );
#     }
#     return $oldval;
# }
# 
# sub free {
#     my $ptr = $_[0]->ptr;
#     Judy::HS::Free( $ptr );
#     $_[0]->setptr( $ptr );
# }
# 
# sub first {
#     my $ptr = $_[0]->ptr;
#     return Judy::HS::First( $ptr, 0 );
# }
# 
# sub next {
#     my $ptr = $_[0]->ptr;
#     return Judy::HS::Next( $ptr, $_[1] );
# }
# 
# sub last {
#     my $ptr = $_[0]->ptr;
#     return Judy::HS::Last( $ptr, 0 );
# }
# 
# sub prev {
#     my $ptr = $_[0]->ptr;
#     return Judy::HS::Prev( $ptr, $_[1] );
# }

1;
