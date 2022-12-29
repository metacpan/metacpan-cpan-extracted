# NAME

Linux::NFTables - Perl interface to [libnftables](https://netfilter.org/projects/nftables/)

# SYNOPSIS

    my $nft = Linux::NFTables->new()->set_output_options('json');

    my $json = $nft->run_cmd("list tables");

# DESCRIPTION

This module provides a Perl interface to
[nftables](https://netfilter.org/projects/nftables/).

# CHARACTER\_ENCODING

Strings into & out of this module are byte strings.

# METHODS

## $obj = _CLASS_->new()

Instantiates _CLASS_.

## $yn = _OBJ_->get\_dry\_run()

Returns a boolean that indicates whether _OBJ_ is set to dry-run mode.

## $obj = _OBJ_->set\_dry\_run( \[$yn\] )

Sets or unsets dry-run mode in _OBJ_. If the parameter is not given,
this defaults to **ON**.

## $output = _OBJ_->run\_cmd( $CMD )

Passes an arbitrary command string to nftables and returns its output.

## @opts = _OBJ_->get\_output\_options()

Returns a list of names, e.g., `json` or `guid`. Must be called
in list context.

Possible values are libnftables’s various `NFT_CTX_OUTPUT_*` constants
(minus that prefix).

## $obj = _OBJ_->set\_output\_options( @NAMES )

A setter complement to `get_output_options()`.

## @opts = _OBJ_->get\_debug\_options()

Like `get_output_options()` but for debug options.

Possible values are libnftables’s various `NFT_DEBUG_*` constants
(minux that prefix).

## $obj = _OBJ_->set\_debug\_options( @NAMES )

A setter complement to `get_debug_options()`.
