package Judy::HS;

# use strict;
# use warnings;
# 
# use Judy::_obj -impl;
# 
# sub TIEHASH {
#     my @self;
#     
#     # I wish I had := binding here.
#     for ( $_[1] ) {
#         for ( $_->{ptrpath} ) {
#             $self[_ptrpath] = $_ if $_;
#         }
#         for ( $_->{ptr} ) {
#             $self[_ptr]    = $_ if $_;
#         }
#     }
# 
#     return bless \@self, $_[0];
# }
# 
# sub FETCH {
#     my $ptr = $_[0]->ptr;
#     my ( undef, $val ) = Get( $ptr, $_[1] );
#     return $val;
# }
# 
# sub STORE {
#     my $ptr = my $optr = $_[0]->ptr;
#     my $val = defined $_[2] ? $_[2] : 0;
#     my $pval = Set( $ptr, $_[1], $val );
#     if ( $optr != $ptr ) {
#         $_[0]->setptr( $ptr );
#     }
#     return $val;
# }
# 
# sub EXISTS {
#     my $ptr = $_[0]->ptr;
#     my ( $pval ) = Get( $ptr, $_[1] );
#     return !! $pval;
# }
# 
# sub DELETE {
#     my $optr = my $ptr = $_[0]->ptr;
# 
#     my $val;
#     if ( defined wantarray ) {
#         ( undef, $val ) = Get( $ptr, $_[1] );
#         return if ! defined $val;
#     }
#     
#     Delete( $ptr, $_[1] );
#     if ( $optr != $ptr ) {
#         $_[0]->setptr( $ptr );
#     }
#     
#     return $val;
# }
# 
# sub CLEAR {
#     my $optr = my $ptr = $_[0]->ptr;
#     Free( $ptr );
#     if ( $optr != $ptr ) {
#         $_[0]->setptr( $ptr );
#     }
# }
# 
# # Not implemented because JudyHS itself has no enumeration.
# # See http://perlmonks.org/?node_id=733140
# sub FIRSTKEY;
# sub NEXTKEY;
# 
# # Not implemented.
# sub SCALAR;
# 
# sub UNTIE {}
# 
# sub DESTROY {}

1;
