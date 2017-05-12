#include "libraw/libraw.h"
#include <cstdlib>
#include "bindpp.h"

// hack. defined strerror in some perl headers?
#ifdef strerror
#undef strerror
#endif

const int REQUIRED_MAJOR = 0;
const int REQUIRED_MINOR = 7;
const int REQUIRED_PATCH = 1;

XS(xs_new) {
    pl::Ctx c(1);

    LibRaw * obj = new LibRaw();
    pl::Pointer self((void*)obj, "Image::LibRaw");
    c.ret(&self);
}

XS(xs_open_file) {
    pl::Ctx c(2);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    pl::Str * fname = c.arg(1)->as_str();
    c.ret(self->open_file(fname->to_c()));
}

XS(xs_get_idata) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();

    pl::Hash res;
    res.store("make", self->imgdata.idata.make);
    res.store("model", self->imgdata.idata.model);
    res.store("raw_count", self->imgdata.idata.raw_count);
    res.store("dng_version", self->imgdata.idata.dng_version);
    res.store("is_foveon", self->imgdata.idata.is_foveon);
    res.store("colors", self->imgdata.idata.colors);
    res.store("filters", self->imgdata.idata.filters);
    res.store("cdesc", self->imgdata.idata.cdesc);

    c.ret(res.reference());
}

XS(xs_get_sizes) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    pl::Hash res;
    res.store("raw_height", self->imgdata.sizes.raw_height);
    res.store("raw_width", self->imgdata.sizes.raw_width);
    res.store("height", self->imgdata.sizes.height);
    res.store("width", self->imgdata.sizes.width);
    res.store("top_margin", self->imgdata.sizes.top_margin);
    res.store("left_margin", self->imgdata.sizes.left_margin);
    res.store("bottom_margin", self->imgdata.sizes.bottom_margin);
    res.store("right_margin", self->imgdata.sizes.right_margin);
    res.store("iheight", self->imgdata.sizes.iheight);
    res.store("iwidth", self->imgdata.sizes.iwidth);
    res.store("pixel_aspect", self->imgdata.sizes.pixel_aspect);
    res.store("flip", self->imgdata.sizes.flip);
    c.ret(res.reference());
}

XS(xs_get_other) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    pl::Hash res;
    res.store("iso_speed",  self->imgdata.other.iso_speed);
    res.store("shutter",    self->imgdata.other.shutter);
    res.store("aperture",   self->imgdata.other.aperture);
    res.store("focal_len",  self->imgdata.other.focal_len);
    res.store("timestamp",  self->imgdata.other.timestamp);
    res.store("shot_order", self->imgdata.other.shot_order);
    // gpsdata does not handled yet
    res.store("desc",       self->imgdata.other.desc);
    res.store("artist",     self->imgdata.other.artist);
    c.ret(res.reference());
}

XS(xs_unpack) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    c.ret(self->unpack());
}

XS(xs_unpack_thumb) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    c.ret(self->unpack_thumb());
}

XS(xs_dcraw_thumb_writer) {
    pl::Ctx c(2);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    pl::Str * fname = c.arg(1)->as_str();
    c.ret(self->dcraw_thumb_writer(fname->to_c()));
}
XS(xs_dcraw_ppm_tiff_writer) {
    pl::Ctx c(2);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    pl::Str * fname = c.arg(1)->as_str();
    c.ret(self->dcraw_ppm_tiff_writer(fname->to_c()));
}

XS(xs_rotate_fuji_raw) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    c.ret(self->rotate_fuji_raw());
}
XS(xs_recycle) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    self->recycle();
    c.return_true();
}
XS(xs_version) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    c.ret(self->version());
}
XS(xs_version_number) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    c.ret(self->versionNumber());
}
XS(xs_camera_count) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    c.ret(self->cameraCount());
}
XS(xs_camera_list) {
    pl::Ctx c(1);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();

    pl::Array ary;
    const char ** list = self->cameraList();
    while (*list) {
        ary.push(*list);
        list++;
    }
    c.ret(&ary);
}
XS(xs_strerror) {
    pl::Ctx c(2);

    LibRaw * self = c.arg(0)->as_pointer()->extract<LibRaw*>();
    pl::Int * i = c.arg(1)->as_int();
    c.ret(self->strerror(i->to_c()));
}

XS(xs_destroy) {
    pl::Ctx c(1);

    pl::Pointer * p = c.arg(0)->as_pointer();
    LibRaw * img = p->extract<LibRaw*>();
    delete img;
    c.return_true();
}

extern "C" {
    XS(boot_Image__LibRaw) {
        pl::BootstrapCtx bc;

        if (! LIBRAW_CHECK_VERSION(REQUIRED_MAJOR, REQUIRED_MINOR, REQUIRED_PATCH)) {
            pl::Carp::croak("Your libraw is too old.This module requires libraw>=%d.%d.%d.",
                REQUIRED_MAJOR, REQUIRED_MINOR, REQUIRED_PATCH
            );
        }

        pl::Package b("Image::LibRaw", __FILE__);
        b.add_method("new",                   xs_new                 );
        b.add_method("open_file",             xs_open_file           );
        b.add_method("get_idata",             xs_get_idata           );
        b.add_method("get_sizes",             xs_get_sizes           );
        b.add_method("get_other",             xs_get_other           );
        b.add_method("unpack",                xs_unpack              );
        b.add_method("unpack_thumb",          xs_unpack_thumb        );
        b.add_method("dcraw_thumb_writer",    xs_dcraw_thumb_writer  );
        b.add_method("dcraw_ppm_tiff_writer", xs_dcraw_ppm_tiff_writer);
        b.add_method("recycle",               xs_recycle             );
        b.add_method("version",               xs_version             );
        b.add_method("version_number",        xs_version_number      );
        b.add_method("camera_count",          xs_camera_count        );
        b.add_method("camera_list",           xs_camera_list         );
        b.add_method("rotate_fuji_raw",       xs_rotate_fuji_raw     );
        b.add_method("strerror",              xs_strerror            );
        b.add_method("DESTROY",               xs_destroy             );
    }
}

