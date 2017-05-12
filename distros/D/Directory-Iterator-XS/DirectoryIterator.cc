#include "DirectoryIterator.hh"
#include "perl_error.hh"
#include <cstdio>
#include <cstring>
#include <sys/stat.h>

#ifndef DIRECTORY_SEPARATOR
# define DIRECTORY_SEPARATOR /
#endif

#define str2(arg) str1(arg)
#define str1(arg) #arg

const std::string DirectoryIterator::separator_(str2(DIRECTORY_SEPARATOR));

bool DirectoryIterator::scan () 
{
  struct dirent entry;
  struct dirent *de;
  while (readdir_r(dh_,&entry,&de) == 0) 
    {
      if (de == 0)
	break;
      
      if (de->d_name[0] == '.') 
	{
	  if (not show_dotfiles_)
	    continue;
	  if (de->d_name[1] == 0)
	    continue;
	  if ((de->d_name[1] == '.') and (de->d_name[2] == 0))
	    continue;
	};
      

#ifdef _DIRENT_HAVE_D_TYPE
      switch (de->d_type) 
	{
	case DT_DIR:
	  if ( do_recurse_ )
	      dirs_.push_back( dir_ + separator_ + de->d_name );
	  if (show_directories_) 
	      {
		  file_ = de->d_name;
		  is_dir_ = true;
		  return true;
	      }
	  
	  break;
	case DT_REG:
	  {
	    file_ = de->d_name;
	    is_dir_ = false;
	    return true;
	  }
	  
	case DT_UNKNOWN:
#endif
	  {
	    std::string path = dir_ + separator_ + de->d_name;
	    struct stat buf;
	    lstat(path.c_str(), &buf);
	    if (S_ISDIR(buf.st_mode)) 
	      {
		if (do_recurse_)
		    dirs_.push_back( path );

		if (show_directories_) 
		    {
			file_ = de->d_name;
			is_dir_ = true;
			return true;
		    }
	      }
	    else if (S_ISREG(buf.st_mode)) 
	      {
		file_ = de->d_name;
		is_dir_ = false;
		return true;
	      }
	  }
	  
#ifdef _DIRENT_HAVE_D_TYPE
	}
#endif
    }
  file_ = "";
  return false;
}

bool DirectoryIterator::next () 
{
  if (dh_) 
    {
      if ( scan() )
	return true;
      else
	{
	  closedir( dh_ );
	  dh_ = 0;
	}
      
    }
  while( dirs_.size() ) 
    {
      dir_.swap(dirs_.back());
      dirs_.pop_back();
      dh_ = opendir(dir_.c_str());
      if (dh_ == NULL)
	{
	  perl_error::error(dir_.c_str());
	}
      else
	{
	  if ( scan() ) return true;
	}
    }
  return false;
  
}

  
void DirectoryIterator::prune() 
{
  if (dh_) closedir(dh_);
  dh_ = 0;
  
#if 0
  dir_ += separator_;
  while ( dirs_.back().compare(dir_, 0, dir_.size()) == 0) 
    {
      dirs_.pop_back();
    }
#endif
  dir_ = "";
  
}

std::string DirectoryIterator::prune_directory() 
{
    std::string back;
    if (not dirs_.empty()) 
	{
	    back.swap( dirs_.back() );
	    dirs_.pop_back();
	}
    return back;
}
