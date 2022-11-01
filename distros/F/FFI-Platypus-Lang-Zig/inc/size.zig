const std = @import("std");

// isize, usize, c_short c_ushort c_int c_uint c_longlong c_ulonglong c_longdouble bool

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("c_short     = sint{d}\n", .{@sizeOf(c_short)*8});
    try stdout.print("c_int       = sint{d}\n", .{@sizeOf(c_int)*8});
    try stdout.print("c_long      = sint{d}\n", .{@sizeOf(c_long)*8});
    try stdout.print("c_longlong  = sint{d}\n", .{@sizeOf(c_longlong)*8});
    try stdout.print("bool        = uint{d}\n", .{@sizeOf(bool)*8});
    try stdout.print("isize       = sint{d}\n", .{@sizeOf(isize)*8});

    try stdout.print("c_ushort    = uint{d}\n", .{@sizeOf(c_ushort)*8});
    try stdout.print("c_uint      = uint{d}\n", .{@sizeOf(c_uint)*8});
    try stdout.print("c_ulong     = uint{d}\n", .{@sizeOf(c_ulong)*8});
    try stdout.print("c_ulonglong = uint{d}\n", .{@sizeOf(c_ulonglong)*8});
    try stdout.print("usize       = uint{d}\n", .{@sizeOf(usize)*8});
}
