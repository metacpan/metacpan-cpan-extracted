const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libtest = b.addLibrary(.{
        .name = "test",
        .linkage = .dynamic,
        .version = .{ .major = 1, .minor = 2, .patch =3 },
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(libtest);
}
