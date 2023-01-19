#Gobally disable warnings
$SIG{__WARN__} =sub {};
$SIG{__DIE__} =sub {};
1;
=head1 NAME

Error::Show::Internal - Internal helper modules for Error::Show

=head1 DESCRIPTION

Used internally by C<Error::Show> to disable warnings when syntax checking


