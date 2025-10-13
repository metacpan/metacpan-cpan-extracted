const std = @import("std");

// isize, usize, c_short c_ushort c_int c_uint c_longlong c_ulonglong c_longdouble bool

pub fn main() !void {

    std.debug.print("c_short     = sint{d}\n", .{@sizeOf(c_short)*8});
    std.debug.print("c_int       = sint{d}\n", .{@sizeOf(c_int)*8});
    std.debug.print("c_long      = sint{d}\n", .{@sizeOf(c_long)*8});
    std.debug.print("c_longlong  = sint{d}\n", .{@sizeOf(c_longlong)*8});
    std.debug.print("bool        = uint{d}\n", .{@sizeOf(bool)*8});
    std.debug.print("isize       = sint{d}\n", .{@sizeOf(isize)*8});

    std.debug.print("c_ushort    = uint{d}\n", .{@sizeOf(c_ushort)*8});
    std.debug.print("c_uint      = uint{d}\n", .{@sizeOf(c_uint)*8});
    std.debug.print("c_ulong     = uint{d}\n", .{@sizeOf(c_ulong)*8});
    std.debug.print("c_ulonglong = uint{d}\n", .{@sizeOf(c_ulonglong)*8});
    std.debug.print("usize       = uint{d}\n", .{@sizeOf(usize)*8});
}
