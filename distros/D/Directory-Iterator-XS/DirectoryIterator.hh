#include <string>
#include <vector>
#include <sys/types.h>
#include <dirent.h>

class DirectoryIterator
{
private:
  std::vector<std::string> dirs_;
  bool show_dotfiles_;
  bool show_directories_;
  bool do_recurse_;
    
  DIR * dh_;
  std::string file_;
  std::string dir_;
  static const std::string separator_;
  
  bool is_dir_;
    
  bool scan();
  
public:
  DirectoryIterator( std::string const & dir ) 
  {
    dh_ = 0;
    do_recurse_ = true;
    show_dotfiles_ = false;
    show_directories_ = false;
    
    dirs_.push_back(dir);
  }
  ~DirectoryIterator() 
  {
    if (dh_) closedir(dh_);
  }

  bool next();
 
  void show_dotfiles(bool arg) 
  {
      show_dotfiles_ = arg? true : false;
  }

  void show_directories(bool arg) 
  {
    show_directories_ = arg? true : false;
  }
  
    void recursive(bool arg) 
    {
	do_recurse_ = arg? true : false;
    }
    
    bool is_directory() const
    {
	return is_dir_;
    }
    
  std::string get() const
  {
    return dir_ + separator_ + file_;
  }

  void prune();
  std::string prune_directory();
    
};

  
  
