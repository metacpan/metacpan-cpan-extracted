//! The helper macros. Each collects its trailing arguments as
//! `&[&dyn Display]` and calls the function of the same name.

/// `l!("Hello")`, `l!("Hello %s", name)`
#[macro_export]
macro_rules! l {
    ($id:expr $(, $arg:expr)* $(,)?) => {
        $crate::l($id, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

/// `ln!("%d message", "%d messages", n)`
#[macro_export]
macro_rules! ln {
    ($id:expr, $pl:expr, $n:expr $(, $arg:expr)* $(,)?) => {
        $crate::ln($id, $pl, ($n) as i64, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

/// `lp!("menu", "Open")`
#[macro_export]
macro_rules! lp {
    ($ctxt:expr, $id:expr $(, $arg:expr)* $(,)?) => {
        $crate::lp($ctxt, $id, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

/// `lnp!("menu", "%d file", "%d files", n)`
#[macro_export]
macro_rules! lnp {
    ($ctxt:expr, $id:expr, $pl:expr, $n:expr $(, $arg:expr)* $(,)?) => {
        $crate::lnp($ctxt, $id, $pl, ($n) as i64, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

/// `ld!("emails", "Welcome, %s", name)`
#[macro_export]
macro_rules! ld {
    ($dom:expr, $id:expr $(, $arg:expr)* $(,)?) => {
        $crate::ld($dom, $id, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

/// `ldn!(domain, "%d message", "%d messages", n)`
#[macro_export]
macro_rules! ldn {
    ($dom:expr, $id:expr, $pl:expr, $n:expr $(, $arg:expr)* $(,)?) => {
        $crate::ldn($dom, $id, $pl, ($n) as i64, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

/// `ldp!(domain, ctxt, "Open")`
#[macro_export]
macro_rules! ldp {
    ($dom:expr, $ctxt:expr, $id:expr $(, $arg:expr)* $(,)?) => {
        $crate::ldp($dom, $ctxt, $id, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

/// `ldnp!(domain, ctxt, "%d file", "%d files", n, args…)`
#[macro_export]
macro_rules! ldnp {
    ($dom:expr, $ctxt:expr, $id:expr, $pl:expr, $n:expr $(, $arg:expr)* $(,)?) => {
        $crate::ldnp($dom, Some($ctxt), $id, Some($pl), ($n) as i64, &[$(&$arg as &dyn ::std::fmt::Display),*])
    };
}

// Deferred-translation markers: the msgid(s) come back unchanged so the
// scraper sees them and the lookup happens later. The plural variants give
// the tuple (singular, plural).

/// Marks a msgid; evaluates to it.
#[macro_export]
macro_rules! n_ {
    ($id:expr $(,)?) => {
        $id
    };
}

#[macro_export]
macro_rules! nn_ {
    ($sg:expr, $pl:expr $(,)?) => {
        ($sg, $pl)
    };
}

#[macro_export]
macro_rules! np_ {
    ($ctxt:expr, $id:expr $(,)?) => {
        $id
    };
}

#[macro_export]
macro_rules! nnp_ {
    ($ctxt:expr, $sg:expr, $pl:expr $(,)?) => {
        ($sg, $pl)
    };
}

#[macro_export]
macro_rules! nd_ {
    ($dom:expr, $id:expr $(,)?) => {
        $id
    };
}

#[macro_export]
macro_rules! ndn_ {
    ($dom:expr, $sg:expr, $pl:expr $(,)?) => {
        ($sg, $pl)
    };
}

#[macro_export]
macro_rules! ndp_ {
    ($dom:expr, $ctxt:expr, $id:expr $(,)?) => {
        $id
    };
}

#[macro_export]
macro_rules! ndnp_ {
    ($dom:expr, $ctxt:expr, $sg:expr, $pl:expr $(,)?) => {
        ($sg, $pl)
    };
}
